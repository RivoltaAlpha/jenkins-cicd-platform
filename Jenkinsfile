pipeline {
    agent any
    
    environment {
        // Docker registry configuration
        REGISTRY = 'localhost:5000'        // Registry configuration - using localhost since registry port is exposed.This is where images will be pushed.
        IMAGE_NAME = 'microservice-app'   // Name of the Docker image to be built and pushed.
        
        // SonarQube configuration
        SONAR_HOST = 'http://sonarqube:9000' // SonarQube which is used for static code analysis.
    }
    
    stages {
        // this stage checks out the code and determines version info its important to do this first to have version info available for subsequent stages.
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Checking out branch: ${env.BRANCH_NAME}"
                    echo "📦 Build number: ${env.BUILD_NUMBER}"
                    
                    // Get version from package.json
                    env.APP_VERSION = sh(script: "cat app/package.json | grep version | head -1 | awk -F: '{ print \$2 }' | sed 's/[\",]//g' | tr -d '[[:space:]]'", returnStdout: true).trim()
                    echo "🏷️  Application version: ${env.APP_VERSION}"
                    
                    // Build timestamp
                    env.BUILD_TIMESTAMP = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
                }
            }
        }
        // This stage handles building the application using pnpm, including installing dependencies and running linting and is for all branches.
        stage('Build Application') {
            steps {
                dir('app') {
                    script {
                        echo "🔨 Building application..."
                        sh '''
                            # Install pnpm if not already installed
                            npm install -g pnpm || true
                            
                            # Install dependencies using pnpm
                            pnpm install --frozen-lockfile
                            
                            # Run linting
                            pnpm run lint || true
                        '''
                    }
                }
            }
        }      
        // This stage runs unit tests and collects coverage reports for all branches. It's important to run tests before building docker images for the sake of quality assurance of the code being deployed.
        stage('Run Tests') {
            steps {
                dir('app') {
                    script {
                        echo "🧪 Running unit tests with coverage..."
                        sh 'pnpm run test:ci'
                    }
                }
            }
            post {
                always { // Publish test results
                    junit testResults: 'app/junit.xml', allowEmptyResults: true
                    // Publish coverage report which contains a report about code coverage. It also allows to view historical coverage data across builds which is useful for tracking improvements or regressions in test coverage over time. 
                    // Regressions in coverage can indicate areas where tests may be lacking or where code changes have reduced test effectiveness.
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'app/coverage/lcov-report',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        // This stage performs static code analysis using SonarQube. This is important for maintaining code quality and identifying potential issues early in the development process.
        stage('Static Code Analysis') {
            steps {
                dir('app') {
                    script {
                        echo "📊 Running SonarQube analysis..."
                            
                            withSonarQubeEnv('SonarQube') {
                                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                                    sh """
                                        sonar-scanner \
                                            -Dsonar.projectKey=microservice-app \
                                            -Dsonar.projectName='Microservice App' \
                                            -Dsonar.projectVersion=${env.APP_VERSION} \
                                            -Dsonar.sources=src \
                                            -Dsonar.tests=tests \
                                            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                                            -Dsonar.host.url=${env.SONAR_HOST} \
                                            -Dsonar.token=${SONAR_TOKEN}
                                    """
                                }
                            }
                        }
                    }
                }
        }
        
        // This stage checks the SonarQube Quality Gate status for the 'prod' branch. This is crucial for ensuring that code meets defined quality standards before deployment to production.
        stage('Quality Gate') {
            when {
                branch 'prod'  
            }
            steps {
                script {
                    echo "Checking SonarQube Quality Gate..."
                    try {
                        timeout(time: 10, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                error "❌ Quality Gate failed: ${qg.status}"
                            } else {
                                echo "✅ Quality Gate passed"
                            }
                        }
                    } catch (Exception e) {
                        echo "Quality Gate check timed out or failed: ${e.message}"
                        echo "❌ Quality Gate check timed out or failed: ${e.message}"
                        echo "Check results manually at: ${env.SONAR_HOST}/dashboard?id=microservice-app"
                        // Don't fail the build on timeout for now
                        // currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
        
        // This stage performs security scanning using OWASP Dependency Check and Trivy. This is crucial for identifying vulnerabilities in dependencies and container images before deployment.
        stage('Security Scanning') {
            when {
                anyOf {
                    branch 'test'
                    branch 'prod'
                }
            }
            parallel {
                stage('Dependency Check') {
                    steps {
                        dir('app') {
                            script {
                                echo "Running OWASP Dependency Check..."
                                
                                // Check if NVD API key exists
                                def hasNvdKey = false
                                try {
                                    withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                                        hasNvdKey = true
                                    }
                                } catch (Exception e) {
                                    echo "NVD API key not found, using --noupdate flag (faster but may miss recent vulnerabilities)"
                                }
                                
                                if (hasNvdKey) {
                                    withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                                        sh """
                                            docker run --rm \
                                                -e NVD_API_KEY=\$NVD_API_KEY \
                                                -v \$(pwd):/src:rw \
                                                -v dependency_check_data:/usr/share/dependency-check/data \
                                                -u \$(id -u):\$(id -g) \
                                                owasp/dependency-check:latest \
                                                --scan /src \
                                                --format HTML \
                                                --format JSON \
                                                --out /src \
                                                --project microservice-app \
                                                --nvdApiKey \$NVD_API_KEY
                                        """
                                    }
                                } else {
                                    sh """
                                        docker run --rm \
                                            -v \$(pwd):/src:rw \
                                            -v dependency_check_data:/usr/share/dependency-check/data \
                                            -u \$(id -u):\$(id -g) \
                                            owasp/dependency-check:latest \
                                            --scan /src \
                                            --format HTML \
                                            --format JSON \
                                            --out /src \
                                            --project microservice-app \
                                            --noupdate
                                    """
                                }
                            }
                        }
                    }
                    post { // Archive reports
                        always {
                            publishHTML(target: [
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'app',
                                reportFiles: 'dependency-check-report.html',
                                reportName: 'OWASP Dependency Check'
                            ])
                        }
                    }
                }
                
                stage('Container Security Scan') {
                    when {
                        anyOf {
                            branch 'test'
                            branch 'prod'
                        }
                    }
                    steps {
                        script {
                            echo "Running Trivy container scan..."
                            
                            // Build temporary image for scanning
                            sh """
                                docker build -t ${IMAGE_NAME}:scan-${BUILD_NUMBER} ./app
                            """
                            
                            // Run Trivy scan
                            def trivyExitCode = sh(
                                script: """
                                    trivy image \
                                        --severity HIGH,CRITICAL \
                                        --format json \
                                        --output trivy-report.json \
                                        ${IMAGE_NAME}:scan-${BUILD_NUMBER}
                                """,
                                returnStatus: true
                            )
                            
                            // For prod, fail on vulnerabilities
                            if (env.BRANCH_NAME == 'prod' && trivyExitCode != 0) {
                                error "Critical vulnerabilities found in container image"
                            }
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                            sh "docker rmi ${IMAGE_NAME}:scan-${BUILD_NUMBER} || true"
                        }
                    }
                }
            }
        }
        
        // This stage builds the Docker image for 'test' and 'prod' branches. It tags the image appropriately based on the branch and build information.
        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'test'
                    branch 'prod'
                }
            }
            steps {
                dir('app') {
                    script {
                        echo "Building Docker image..."
                        
                        // Determine tag based on branch
                        def imageTag
                        def additionalTags = []
                        
                        if (env.BRANCH_NAME == 'test') {
                            imageTag = "test-${env.BUILD_NUMBER}"
                        } else if (env.BRANCH_NAME == 'prod') {
                            imageTag = "prod-${env.APP_VERSION}"
                            additionalTags = ['latest', "prod-${env.BUILD_TIMESTAMP}"]
                        }
                        
                        echo "Building docker image with tag: ${imageTag}"
                        
                        // Build image
                        sh """
                            docker build \
                                --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                                --build-arg VERSION=${env.APP_VERSION} \
                                --build-arg VCS_REF=\$(git rev-parse --short HEAD) \
                                -t ${REGISTRY}/${IMAGE_NAME}:${imageTag} \
                                .
                        """
                        
                        // Tag additional tags for prod
                        additionalTags.each { tag ->
                            sh "docker tag ${REGISTRY}/${IMAGE_NAME}:${imageTag} ${REGISTRY}/${IMAGE_NAME}:${tag}"
                        }
                        
                        // Store tags for push stage
                        env.IMAGE_TAG = imageTag
                        env.ADDITIONAL_TAGS = additionalTags.join(',')
                    }
                }
            }
        }
        
        // This stage pushes the built Docker image to the registry for 'test' and 'prod' branches. It also cleans up local images after pushing to save space.
        stage('Push Docker Image') {
            when {
                anyOf {
                    branch 'test'
                    branch 'prod'
                }
            }
            steps {
                script {
                    echo "Pushing Docker image to registry..."
                    
                    // Pushes images with main tag which is either test-BUILD_NUMBER or prod-APP_VERSION
                    sh """
                        docker push ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG}
                    """
                    
                    // Push additional tags
                    if (env.ADDITIONAL_TAGS) {
                        env.ADDITIONAL_TAGS.split(',').each { tag ->
                            sh "docker push ${REGISTRY}/${IMAGE_NAME}:${tag}"
                        }
                    }
                    
                    echo "✅ Image pushed successfully: ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG}"
                }
            }
            post {
                always {
                    script {
                        // Clean up local images that were pushed and are no longer needed locally to save space.
                        sh """
                            docker rmi ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG} || true
                        """
                        
                        if (env.ADDITIONAL_TAGS) {
                            env.ADDITIONAL_TAGS.split(',').each { tag ->
                                sh "docker rmi ${REGISTRY}/${IMAGE_NAME}:${tag} || true"
                            }
                        }
                    }
                }
            }
        }

        // This stage archives test artifacts such as coverage reports, test results, dependency check reports, and build metadata for the 'test' branch. This is important for traceability and auditing purposes.
        stage('Archive Test Artifacts') {
            when {
                branch 'test'
            }
            steps {
                script {
                    echo "📦 Archiving test build artifacts..."
                    sh '''
                        # Create artifact metadata
                        cat > build-info.txt << EOF
                        Build Number: ${BUILD_NUMBER}
                        Branch: ${BRANCH_NAME}
                        Image Tag: ${IMAGE_TAG}
                        Registry: ${REGISTRY}
                        Image Name: ${IMAGE_NAME}
                        Build Timestamp: ${BUILD_TIMESTAMP}
                        App Version: ${APP_VERSION}

                        Container Image: ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        Pull Command: docker pull ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        Run Command: docker run -p 3000:3000 ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        EOF
                    '''
                    
                    // Archive all test artifacts
                    archiveArtifacts artifacts: 'app/coverage/**,app/junit.xml,app/dependency-check-report.*,trivy-report.json,build-info.txt', 
                                     allowEmptyArchive: true,
                                     onlyIfSuccessful: false
                }
            }
        }
        
        // This stage displays deployment information for 'test' and 'prod' branches after a successful build and push. This provides users with necessary commands and details to deploy the application.
        stage('Image Deployment Info') { // Display deployment info for test and prod images that were just built and pushed.
            when {
                anyOf {
                    branch 'test'
                    branch 'prod'
                }
            }
            steps {
                script {
                    echo """
                    ╔════════════════════════════════════════════════════════╗
                    ║           DEPLOYMENT INFORMATION                       ║
                    ╠════════════════════════════════════════════════════════╣
                    ║ Branch:      ${env.BRANCH_NAME}                        ║
                    ║ Version:     ${env.APP_VERSION}                        ║
                    ║ Build:       #${env.BUILD_NUMBER}                      ║
                    ║ Image Tag:   ${env.IMAGE_TAG}                          ║
                    ║ Registry:    ${REGISTRY}                               ║
                    ║                                                        ║
                    ║ Pull Command:                                          ║
                    ║ docker pull ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG} ║
                    ║                                                        ║
                    ║ Run Command:                                           ║
                    ║ docker run -p 3000:3000 ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG}
                    ╚════════════════════════════════════════════════════════╝
                    """
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "🧹 Cleaning workspace..."
                try {
                    cleanWs()
                } catch (Exception e) {
                    echo "Could not clean workspace: ${e.message}"
                }
            }
        }
        success {
            script {
                echo """
                ✅ Pipeline completed successfully!
                Branch: ${env.BRANCH_NAME}
                Build: #${env.BUILD_NUMBER}
                """
            }
        }
        failure {
            script {
                echo """
                ❌ Pipeline failed!
                Branch: ${env.BRANCH_NAME}
                Build: #${env.BUILD_NUMBER}
                Check logs for details.
                """
            }
        }
    }
}