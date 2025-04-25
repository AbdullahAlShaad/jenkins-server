
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
