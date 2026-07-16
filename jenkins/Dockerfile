# Jenkins with pre-installed plugins and tools
FROM jenkins/jenkins:lts

# Switch to root to install additional tools
USER root

# Install Docker CLI, Node.js, and other tools
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    unzip \
    wget && \
    # Install Docker CLI
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    # Install Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Trivy (using direct binary installation to avoid repo issues)
RUN wget -qO trivy.tar.gz https://github.com/aquasecurity/trivy/releases/download/v0.72.0/trivy_0.72.0_Linux-64bit.tar.gz && \
    tar -zxvf trivy.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/trivy && \
    rm trivy.tar.gz

# Install SonarQube Scanner
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip && \
    unzip sonar-scanner-cli-5.0.1.3006-linux.zip && \
    mv sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner && \
    rm sonar-scanner-cli-5.0.1.3006-linux.zip && \
    ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner

# Install Gitleaks (secret scanning)
RUN wget -qO gitleaks.tar.gz https://github.com/gitleaks/gitleaks/releases/download/v8.21.2/gitleaks_8.21.2_linux_x64.tar.gz && \
    tar -zxvf gitleaks.tar.gz -C /usr/local/bin gitleaks && \
    chmod +x /usr/local/bin/gitleaks && \
    rm gitleaks.tar.gz

# Install Checkov (IaC scanning) - requires Python; Debian bookworm needs --break-system-packages for a global pip install
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    pip3 install --no-cache-dir --break-system-packages --ignore-installed checkov && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Syft (SBOM generation)
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Install jest-junit for test reporting
RUN npm install -g jest-junit

# Copy plugin list
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install Jenkins plugins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy initialization script
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/

# Set permissions for jenkins user to access Docker socket
RUN usermod -aG docker jenkins || groupadd docker && usermod -aG docker jenkins

# Environment variables
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Xmx2g"
ENV JENKINS_OPTS="--prefix=/"

# Switch back to jenkins user
USER jenkins

# Expose ports
EXPOSE 8080 50000