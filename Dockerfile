# Use the LTS version for stability
FROM jenkins/jenkins:lts

# Switch to root to install additional tools
USER root

# Install tools (example: git, docker-cli)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    sudo \
    lsb-release \
    gnupg2 \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# (Optional) Install Docker CLI inside container if Jenkins needs to run docker commands
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for Jenkins
RUN usermod -aG sudo jenkins && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

# Install plugins including Configuration as Code
RUN jenkins-plugin-cli --plugins \
    configuration-as-code \
    git

# Match the docker group ID from the host system (e.g., 998)
ARG DOCKER_GID=1001
RUN groupadd -g ${DOCKER_GID} docker && usermod -aG docker jenkins


# Install Jenkins Configuration as Code plugin support
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs

# Copy your JCasc YAML file
COPY casc_configs /var/jenkins_home/casc_configs

# Switch back to Jenkins user
USER jenkins

# Expose ports (8080 for web UI, 50000 for agent connections)
EXPOSE 8080 50000
