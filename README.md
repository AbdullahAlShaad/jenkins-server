
#  Jenkins Server Setup (Docker + JCasC)

This project sets up a fully automated Jenkins server using Docker, Docker Compose, and Jenkins Configuration as Code (JCasC).

---

##  Folder Structure

```
.
├── Dockerfile                    # Builds the custom Jenkins image
├── docker-compose.yml           # Brings up the Jenkins container
├── casc_configs/
│   └── jenkins.yaml             # Jenkins Configuration as Code (JCasC) settings
└── README.md                    # You're here!
```

## File Contents

### Dockerfile
```bash
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
```

### docker-compose.yaml
```yaml
version: '3.8'

services:
  jenkins:
    build: .
    container_name: jenkins-prod
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - ./casc_configs:/var/jenkins_home/casc_configs:ro   # JCasC mount
      - jenkins_home:/var/jenkins_home                     # Jenkins persistent storage
      - /var/run/docker.sock:/var/run/docker.sock          # Docker socket for pipeline usage
      - /root/.docker:/root/.docker                        # Optional: Docker auth config
      - /home/shaad/bookstore-api-server:/workspace/bookstore-api-server:cached  # Project workspace

    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false   # Skip wizard
      - CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs # JCasC path

    restart: unless-stopped
    networks:
      - jenkins-net

    # It marks the docker container unhealth on failure
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/login"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  jenkins_home:

networks:
  jenkins-net:
    driver: bridge
```

### casc_configs/jenkins.yaml
```yaml
jenkins:
  systemMessage: "Jenkins configured by Configuration as Code 💡"
  numExecutors: 2

  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          name: "admin"
          password: "admin123"

  authorizationStrategy:
    loggedInUsersCanDoAnything:
      allowAnonymousRead: false

unclassified:
  location:
    adminAddress: "admin@example.com"
    url: "http://localhost:8080/"

  buildDiscarders:
    configuredBuildDiscarders:
      - "jobBuildDiscarder"  # Respect per-job log rotation settings
      - simpleBuildDiscarder:
          discarder:
            logRotator:
              daysToKeepStr: "7"             # Keep builds for 7 days max
              numToKeepStr: "10"             # Keep last 10 builds max
              artifactDaysToKeepStr: "3"     # Keep artifacts for 3 days max
              artifactNumToKeepStr: "5"      # Keep only 5 latest artifacts

tool:
  git:
    installations:
      - name: "Default"
        home: "/usr/bin/git"
```

---

##  Features
-  Jenkins LTS inside Docker
-  Configuration as Code (JCasC)
-  Basic authentication setup using JCasC
-  Auto-cleanup of old builds & artifacts
-  Persistent Jenkins home directory
-  Health checks and restart policies

---

##  Prerequisites

- Docker
- Docker Compose

---

##  Configuration Details

###  Dockerfile

- Installs: `git`, `docker-cli`, `sudo`
- Installs Jenkins plugins: `git`, `configuration-as-code`
- Sets up Jenkins user with `sudo` & Docker group access
- Configures Docker CLI inside the Jenkins container

###  docker-compose.yml

- Mounts volumes for:
  - JCasC config
  - Jenkins home
  - Docker socket for running Docker inside pipelines
- Healthcheck to ensure Jenkins is up
- Binds ports: `8080` (UI), `50000` (agents)
- Runs the container in a seperate docker network

###  JCasC (jenkins.yaml)

- Admin user (`admin` / `admin123`)
- Security: Only authenticated users can access
- Log rotation:
  - Keep builds for **7 days** or **last 10**
  - Keep artifacts for **3 days** or **last 5**
- Git tool pre-configured

---

##  Getting Started

```bash
# Create a docker network
docker network create jenkins-network

# Build Jenkins image
docker compose build

# Run Jenkins server
docker compose up -d
```

Visit: [http://localhost:8080](http://localhost:8080)  
Login:  
- **Username**: `admin`  
- **Password**: `admin123`

Install necessary plugins like `Pipeline`

```bash
# To stop jenkins server
docker compose down
```

---

##  Useful Tips

- To update JCasC config, modify files in `casc_configs/` and restart the container.
- Log rotation ensures Jenkins doesn’t accumulate excessive build data.
- You can connect your own pipeline projects via mounted volumes (see example path `/home/shaad/bookstore-api-server`).
- You can extend the `Dockerfile` to install more tools as needed.

---

##  Extras

-  Jenkins state is saved in a Docker volume (`jenkins_home`)
-  Docker group ID is matched to host for safe socket access
-  Jenkins install wizard is skipped via `JAVA_OPTS`

---
