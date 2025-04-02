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
                ${tool 'Snyk'}/snyk-macos test --severity-threshold=low
            """
        }
    }
    
    stage('Code Scan'){
        withSonarQubeEnv(credentialsId: 'SonarQubeCreds') {
            sh "${sonarHome}/bin/sonar-scanner"
        }
    }
    
    stage('Code Deployment'){
        deploy adapters: [tomcat9(credentialsId: 'TomcatCreds', path: '', url: 'http://54.197.62.94:8080/')], contextPath: 'Planview', onFailure: false, war: 'target/*.war'
    }
}
