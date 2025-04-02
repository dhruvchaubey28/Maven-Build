node(){
    def sonarHome = tool name: 'SonarScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
    def mvnHome = tool name: 'mvn', type: 'hudson.tasks.Maven$MavenInstallation'
    
    stage('Code Checkout'){
        checkout changelog: false, poll: false, scm: scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'GitHubCreds', url: 'https://github.com/dhruvchaubey28/Maven-Build']])
    }
    
    stage('Build Automation'){
        sh """
            ls -lart
            ${mvnHome}/bin/mvn clean install
            ls -lart target
        """
    }
    
    stage('Security Scan'){
        // Add Maven to PATH before running Snyk
        withEnv(["PATH+MAVEN=${mvnHome}/bin"]) {
            sh """
                echo "Maven should now be in PATH: \$PATH"
                which mvn
                mvn --version
                
                # Run Snyk with JSON output and fail on high/critical vulnerabilities
                ${tool 'Snyk'}/snyk-macos test \
                    --severity-threshold=high \
                    --json-file-output=snyk_results.json \
                    || echo "Snyk scan found vulnerabilities"
                
                # Optional: Archive the results
                archiveArtifacts artifacts: 'snyk_results.json', onlyIfSuccessful: false
            """
        }
        
        // Optional: Add quality gate for Snyk results
        script {
            if (fileExists('snyk_results.json')) {
                def snykResults = readJSON file: 'snyk_results.json'
                if (snykResults.vulnerabilities?.high || snykResults.vulnerabilities?.critical) {
                    error("Snyk scan detected high/critical vulnerabilities - failing build")
                }
            }
        }
    }
    
    stage('Code Scan'){
        withSonarQubeEnv(credentialsId: 'SonarQubeCreds') {
            sh "${sonarHome}/bin/sonar-scanner"
        }
        
        // Add SonarQube quality gate check
        timeout(time: 15, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
    
    stage('Code Deployment'){
        deploy adapters: [tomcat9(credentialsId: 'TomcatCreds', path: '', url: 'http://54.197.62.94:8080/')], contextPath: 'Planview', onFailure: false, war: 'target/*.war'
    }
    
    // Post-build actions
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
        failure {
            // Notify on failure
            mail to: 'team@example.com',
                 subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                 body: "Check failed build at: ${env.BUILD_URL}"
        }
    }
}
