node() {
    def sonarHome = tool name: 'SonarScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
    def mvnHome = tool name: 'mvn', type: 'hudson.tasks.Maven$MavenInstallation'
    
    // Get the full path to Maven executable
    def mvnPath = "${mvnHome}/bin/mvn"
    
    stage('Code Checkout') {
        checkout scm
    }
    
    stage('Build Automation') {
        sh """
            ${mvnPath} clean install
        """
    }
    
    stage('Security Scan') {
        // First verify Maven works
        sh """
            echo "Verifying Maven installation..."
            ${mvnPath} --version
            ${mvnPath} dependency:tree -DoutputType=dot
        """
        
        // Then run Snyk with explicit Maven command
        sh """
            echo "Running Snyk scan..."
            ${tool 'Snyk'}/snyk-macos test \
                --severity-threshold=high \
                --json-file-output=snyk_results.json \
                --command="${mvnPath} dependency:tree"
            
            // Archive results regardless of scan outcome
            archiveArtifacts artifacts: 'snyk_results.json', onlyIfSuccessful: false
        """
        
        // Evaluate results
        script {
            if (fileExists('snyk_results.json')) {
                def snykResults = readJSON file: 'snyk_results.json'
                if (snykResults.vulnerabilities?.high || snykResults.vulnerabilities?.critical) {
                    error("Snyk scan detected high/critical vulnerabilities")
                }
            } else {
                error("Snyk results file not found - scan may have failed")
            }
        }
    }
    
    // Rest of your stages...
    stage('Code Scan') {
        withSonarQubeEnv(credentialsId: 'SonarQubeCreds') {
            sh "${sonarHome}/bin/sonar-scanner"
        }
        timeout(time: 15, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
    
    stage('Code Deployment') {
        deploy adapters: [tomcat9(credentialsId: 'TomcatCreds', path: '', url: 'http://54.197.62.94:8080/')], 
              contextPath: 'Planview', 
              onFailure: false, 
              war: 'target/*.war'
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            mail to: 'team@example.com',
                 subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                 body: "Check failed build at: ${env.BUILD_URL}"
        }
    }
}
