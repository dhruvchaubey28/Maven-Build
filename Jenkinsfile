node() {
    def sonarHome = tool name: 'SonarScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
    def mvnHome = tool name: 'mvn', type: 'hudson.tasks.Maven$MavenInstallation'
    
    stage('Code Checkout') {
        checkout changelog: false, poll: false, scm: scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'GitHubCreds', url: 'https://github.com/dhruvchaubey28/Maven-Build']])
    }
    
    stage('Build Automation') {
        sh """
            ls -lart
            ${mvnHome}/bin/mvn clean install
            ls -lart target
        """
    }
    
    stage('Security Scan') {
        // Explicitly set the full path to Maven for Snyk
        def mvnPath = "${mvnHome}/bin/mvn"
        sh """
            echo "Using Maven from: ${mvnPath}"
            ${mvnPath} --version
            
            # Run Snyk with the explicit Maven path
            ${tool 'Snyk'}/snyk-macos test \
                --severity-threshold=high \
                --json-file-output=snyk_results.json \
                --command="${mvnPath} dependency:tree" \
                || echo "Snyk scan found vulnerabilities"
            
            # Archive the results
            archiveArtifacts artifacts: 'snyk_results.json', onlyIfSuccessful: false
        """
        
        // Quality gate for Snyk results
        script {
            if (fileExists('snyk_results.json')) {
                def snykResults = readJSON file: 'snyk_results.json'
                if (snykResults.vulnerabilities?.high || snykResults.vulnerabilities?.critical) {
                    error("Snyk scan detected high/critical vulnerabilities - failing build")
                }
            }
        }
    }
    
    stage('Code Scan') {
        withSonarQubeEnv(credentialsId: 'SonarQubeCreds') {
            sh "${sonarHome}/bin/sonar-scanner"
        }
        
        timeout(time: 15, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
    
    stage('Code Deployment') {
        deploy adapters: [tomcat9(credentialsId: 'TomcatCreds', path: '', url: 'http://54.197.62.94:8080/')], contextPath: 'Planview', onFailure: false, war: 'target/*.war'
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
