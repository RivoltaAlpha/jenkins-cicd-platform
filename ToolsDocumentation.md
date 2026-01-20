# Jenkins CI/CD Platform - Complete Setup Guide

## Table of Contents

1. [Quick Start](#quick-start)
2. [Platform Components](#platform-components)
3. [Working with the Microservice](#working-with-the-microservice)
4. [Working with Observability Tools](#working-with-observability-tools)
5. [Troubleshooting](#troubleshooting)

---

## Overview

This is a complete CI/CD platform running on Docker Compose that includes:
- **Jenkins** - CI/CD automation
- **Docker Registry** - Container image storage
- **SonarQube** - Static code analysis
- **OWASP Dependency Check** - Dependency vulnerability scanning
- **Trivy** - Container security scanning
- **Prometheus** - Metrics collection
- **Grafana** - Metrics visualization
- **Loki** - Log aggregation
- **Alertmanager** - Alert management
- **Node Exporter** - System metrics
- **cAdvisor** - Container metrics

---

## Quick Start

### Step 1: Start the Platform

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/jenkins-cicd-platform.git
cd jenkins-cicd-platform

# Start all services
docker-compose up -d

# Monitor startup (takes ~2-3 minutes)
docker-compose logs -f jenkins
# Wait for: "Jenkins is fully up and running"
```

### Step 2: Verify All Services are Running

```bash
# Check all containers are healthy
docker-compose ps

# Expected output: All services should show "Up" status
```

### Step 3: Access the Platform

Open your browser and access these URLs:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Jenkins** | http://localhost:8080 | admin / admin123 |
| **SonarQube** | http://localhost:9000 | admin / admin |
| **Grafana** | http://localhost:3000 | admin / admin123 |
| **Prometheus** | http://localhost:9090 | No auth |
| **Docker Registry** | http://localhost:5000 | No auth |
| **Alertmanager** | http://localhost:9093 | No auth |

---

## Platform Components

### 1. Jenkins (CI/CD Server)

**Purpose**: Automates building, testing, and deploying your application.

**Access**: http://localhost:8080  
**Credentials**: `admin` / `admin123`

**What it does**:
- Monitors Git branches (develop, test, prod)
- Runs automated tests
- Performs security scans
- Builds Docker images
- Pushes images to registry

**Key Features**:
- ✅ Persistent storage (survives container restarts)
- ✅ Pre-configured credentials
- ✅ Automatic job creation
- ✅ Prometheus metrics enabled

**How to use**:
1. Navigate to http://localhost:8080
2. Log in with `admin` / `admin123`
3. Click on your pipeline job
4. Click "Scan Repository Now" to detect branches
5. View build history and logs

---

### 2. Docker Registry

**Purpose**: Stores Docker images built by Jenkins.

**Access**: http://localhost:5000  
**API**: http://localhost:5000/v2/_catalog
**Check specific image tags**: http://localhost:5000/v2/microservice-app/tags/list

**What it does**:
- Stores container images
- Supports versioned tags (test-1, prod-1.0.0, latest)
- Provides image catalog

**How to use**:

```bash
# List all images in registry
curl http://localhost:5000/v2/_catalog

# List tags for specific image
curl http://localhost:5000/v2/microservice-app/tags/list

# Pull an image
docker pull localhost:5000/microservice-app:latest

# Push an image
docker tag my-app:latest localhost:5000/my-app:v1.0
docker push localhost:5000/my-app:v1.0
```

---

### 3. SonarQube (Code Quality Analysis)

**Purpose**: Analyzes code quality, identifies bugs, code smells, and security vulnerabilities.

**Access**: http://localhost:9000  
**Credentials**: `admin` / `admin` (change on first login)

**What it does**:
- Static code analysis
- Code coverage tracking
- Security hotspot detection
- Technical debt calculation
- Quality gate enforcement

**How to use**:
1. Navigate to http://localhost:9000
2. Log in with `admin` / `admin`
3. Click on "Projects" → "microservice-app"
4. View:
   - **Overview**: Summary of issues, coverage, duplications
   - **Issues**: Detailed list of bugs, vulnerabilities, code smells
   - **Measures**: Code metrics and trends
   - **Activity**: History of analyses

**Quality Gate (Prod Only)**:
- The prod branch must pass quality gate checks
- Failed quality gate = build fails
- Configure thresholds in SonarQube UI

---

### 4. Trivy (Container Security Scanner)

**Purpose**: Scans Docker images for vulnerabilities.

**View Scan Results in Jenkins**
After a build runs on test/prod branches:

Go to Jenkins build
Click "Artifacts"
Download trivy-report.json

---

### 5. OWASP Dependency Check

**Purpose**: Identifies known vulnerabilities in project dependencies.

**Access**: Reports in Jenkins builds  
**Report**: Available as HTML in Jenkins

**What it does**:
- Scans package.json dependencies
- Checks against NVD database
- Generates HTML/JSON reports

**How to use**:
1. Run a test or prod build in Jenkins
2. After build completes, click "OWASP Dependency Check"
3. View detailed vulnerability report

**Speed up scans**:
```bash
# Get free NVD API key: https://nvd.nist.gov/developers/request-an-api-key
# Add to Jenkins:
# Manage Jenkins → Credentials → Add → Secret text
# ID: nvd-api-key
# Secret: <your-api-key>
```

---

## Working with the Microservice

### Running the Application Locally

#### Option 1: Using Node.js directly

```bash
cd app

# Install dependencies
npm install -g pnpm
pnpm install

# Run in development mode
pnpm start

# Run tests
pnpm test

# Run linting
pnpm run lint
```

#### Option 2: Using Docker

```bash
# Build the image
docker build -t microservice-app:local ./app

# Run the container
docker run -p 3000:3000 microservice-app:local
```

#### Option 3: Pull from Registry (after pipeline runs)

```bash
# Pull latest image
docker pull localhost:5000/microservice-app:latest

# Run the container
docker run -p 3000:3000 localhost:5000/microservice-app:latest
```

---

### Testing the Health Endpoint

Once the application is running, test the health endpoint:

```bash
# Check health status
curl http://localhost:3000/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2026-01-20T10:30:45.123Z",
  "uptime": 123.456,
  "version": "1.0.0"
}
```

**Health Check Returns**:
- `status`: "healthy" if app is running
- `timestamp`: Current ISO timestamp
- `uptime`: Seconds since app started
- `version`: Application version from package.json

---

### Other API Endpoints

```bash
# Get application info
curl http://localhost:3000/api/info

# Perform calculation
curl -X POST http://localhost:3000/api/calculate \
  -H "Content-Type: application/json" \
  -d '{"operation": "add", "a": 5, "b": 3}'

# View all available endpoints
curl http://localhost:3000/
```

---

## Working with Observability Tools

### Prometheus (Metrics Collection)

**Purpose**: Collects and stores time-series metrics.

**Access**: http://localhost:9090

**What it monitors**:
- Jenkins build metrics
- Container resource usage (CPU, memory)
- System metrics (disk, network)
- Application metrics

**How to use**:

1. **Explore Metrics**:
   - Navigate to http://localhost:9090
   - Click "Graph"
   - Enter a metric name in the query box

2. **Useful Queries**:

```promql
# Jenkins build count
default_jenkins_builds_total_build_count_total

# Jenkins build success rate
rate(default_jenkins_builds_success_build_count_total[5m])

# Jenkins build failures
default_jenkins_builds_failed_build_count_total

# Container CPU usage
rate(container_cpu_usage_seconds_total[5m])

# Container memory usage
container_memory_usage_bytes

# System CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Disk usage
(node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100
```

3. **View Targets**:
   - Click "Status" → "Targets"
   - Verify all endpoints are "UP"

---

### Grafana (Metrics Visualization)

**Purpose**: Visualizes metrics from Prometheus and Loki.

**Access**: http://localhost:3000  
**Credentials**: `admin` / `admin123`

**Pre-configured Dashboards**:
- Jenkins Performance Dashboard
- System Metrics
- Container Metrics

**How to use**:

1. **Access Dashboards**:
   - Navigate to http://localhost:3000
   - Log in with `admin` / `admin123`
   - Click "Dashboards" icon (left sidebar)
   - Select "Jenkins Performance"

2. **View Jenkins Metrics**:
   - Total builds
   - Success/failure rates
   - Build duration trends
   - Queue length

3. **Create Custom Dashboard**:
   - Click "+" → "Dashboard"
   - Click "Add visualization"
   - Select "Prometheus" as data source
   - Enter PromQL query
   - Customize visualization

4. **View Logs in Grafana**:
   - Click "Explore" icon (compass)
   - Select "Loki" as data source
   - Use LogQL queries:
     ```logql
     {container_name="jenkins"}
     {container_name="jenkins"} |= "error"
     {container_name="jenkins"} |= "failed"
     ```

---

### Loki (Log Aggregation)

**Purpose**: Collects and indexes logs from all containers.

**Access**: http://localhost:3100  
**Query via Grafana**: http://localhost:3000

**What it does**:
- Aggregates logs from all containers
- Indexes log labels
- Enables fast log searching
- Supports LogQL queries

**How to use**:

1. **Via Grafana**:
   - Go to http://localhost:3000
   - Click "Explore" → Select "Loki"
   - Use LogQL queries

2. **Common LogQL Queries**:

```logql
# All Jenkins logs
{container_name="jenkins"}

# Jenkins errors
{container_name="jenkins"} |= "error"

# Jenkins build failures
{container_name="jenkins"} |= "failed"

# SonarQube logs
{container_name="sonarqube"}

# Registry logs
{container_name="docker-registry"}

# Last 5 minutes of Jenkins logs
{container_name="jenkins"} [5m]

# Count errors in last hour
count_over_time({container_name="jenkins"} |= "error" [1h])
```

3. **Direct API Access**:
```bash
# Query logs
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={container_name="jenkins"}' | jq

# Query range
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={container_name="jenkins"}' \
  --data-urlencode 'start=1h' | jq
```

---

### Alertmanager (Alert Management)

**Purpose**: Manages alerts from Prometheus.

**Access**: http://localhost:9093

**What it does**:
- Receives alerts from Prometheus
- Groups and deduplicates alerts
- Routes alerts (email, Slack, etc.)
- Manages alert silences

**How to use**:

1. **View Active Alerts**:
   - Navigate to http://localhost:9093
   - View all active alerts

2. **Silence Alerts**:
   - Click "New Silence"
   - Set matchers (e.g., `alertname="HighCPU"`)
   - Set duration
   - Add comment
   - Click "Create"

3. **Check Alert Configuration**:
```bash
# View Alertmanager config
docker exec -it alertmanager cat /etc/alertmanager/alertmanager.yml
```

---

### Node Exporter (System Metrics)

**Purpose**: Exposes hardware and OS metrics.

**Access**: http://localhost:9100/metrics  
**Scraped by**: Prometheus

**What it exposes**:
- CPU usage
- Memory usage
- Disk I/O
- Network traffic
- Filesystem usage

**Metrics Examples**:
```promql
# CPU usage
node_cpu_seconds_total

# Memory available
node_memory_MemAvailable_bytes

# Disk read/write
rate(node_disk_read_bytes_total[5m])
rate(node_disk_written_bytes_total[5m])

# Network traffic
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

---

### cAdvisor (Container Metrics)

**Purpose**: Analyzes resource usage and performance of running containers.

**Access**: http://localhost:8082  
**Scraped by**: Prometheus

**What it monitors**:
- Container CPU usage
- Container memory usage
- Container network I/O
- Container disk I/O

**How to use**:

1. **Web UI**:
   - Navigate to http://localhost:8082
   - View all containers
   - Click container name for detailed metrics

2. **Prometheus Queries**:
```promql
# Container CPU usage
rate(container_cpu_usage_seconds_total[5m])

# Container memory
container_memory_usage_bytes

# Container network
rate(container_network_receive_bytes_total[5m])
```

---

## Monitoring Common Scenarios

### "Is Jenkins Healthy?"

**Option 1: Check in Browser**
- Navigate to http://localhost:8080
- If page loads, Jenkins is healthy

**Option 2: Check Container**
```bash
docker-compose ps jenkins
# Should show "Up (healthy)"

docker logs jenkins --tail 50
# Look for errors
```

**Option 3: Check Metrics**
```bash
# Open Prometheus
http://localhost:9090

# Query Jenkins status
up{job="jenkins"}
# Result: 1 = healthy, 0 = down
```

---

### "Did the Pipeline Fail Today?"

**Option 1: Jenkins UI**
- Go to http://localhost:8080
- Check pipeline job
- Look for red/failed builds

**Option 2: Prometheus Query**
```promql
# Count failed builds today
increase(default_jenkins_builds_failed_build_count_total[24h])

# Failed builds in last hour
increase(default_jenkins_builds_failed_build_count_total[1h])

```

**Option 3: Grafana Dashboard**
- Go to http://localhost:3000
- Open "Jenkins Performance" dashboard
- View "Build Failures" panel

---

### "What Errors Are in Jenkins Logs?"

**Option 1: Docker Logs**
```bash
# View recent logs
docker logs jenkins --tail 100

# Follow logs in real-time
docker logs jenkins -f

# Search for errors
docker logs jenkins 2>&1 | grep -i error
```

**Option 2: Loki via Grafana**
```logql
# In Grafana Explore:
{container_name="jenkins"} |= "error"
{container_name="jenkins"} |= "Exception"
{container_name="jenkins"} |~ "(?i)error|exception|failed"
```

**Option 3: Direct Loki Query**
```bash
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={container_name="jenkins"} |= "error"' \
  | jq '.data.result'
```

---

## Creating Branches and Running Pipeline

### Step 1: Create Branches

```bash
# Create develop branch
git checkout -b develop
git push origin develop

# Create test branch
git checkout -b test
git push origin test

# Create prod branch
git checkout -b prod
git push origin prod
```

### Step 2: Configure Jenkins Pipeline

1. Go to http://localhost:8080
2. Click "New Item"
3. Name: `microservice-pipeline`
4. Type: "Multibranch Pipeline"
5. Click "OK"
6. Under "Branch Sources":
   - Add source → Git
   - Repository URL: Your Git URL
7. Click "Save"
8. Click "Scan Repository Now"

### Step 3: Trigger Builds

```bash
# Make change on develop
git checkout develop
echo "// test change" >> app/src/index.ts
git commit -am "test: trigger develop build"
git push origin develop

# Promote to test
git checkout test
git merge develop
git push origin test

# Promote to prod
git checkout prod
git merge test
git push origin prod
```

---

## Pipeline Behavior by Branch

### develop Branch
```
✅ Checkout
✅ Build Application
✅ Run Tests (with coverage reports)
✅ Static Code Analysis (SonarQube)
❌ Quality Gate (skipped)
❌ Security Scanning (skipped)
❌ Build Docker Image (skipped)
❌ Push to Registry (skipped)
```

**Purpose**: Fast feedback for developers  
**Duration**: ~2-5 minutes  
**Artifacts**: Test reports, coverage reports

### test Branch
```
✅ Checkout
✅ Build Application
✅ Run Tests (with coverage reports)
✅ Static Code Analysis (SonarQube)
❌ Quality Gate (skipped)
✅ Security Scanning (OWASP + Trivy)
✅ Build Docker Image (tag: test-{BUILD_NUMBER})
✅ Push to Registry
✅ Archive Artifacts (coverage, reports, build-info)
```

**Purpose**: Validate release candidate  
**Duration**: ~10-15 minutes  
**Artifacts**: All reports + Docker image

### prod Branch
```
✅ Checkout
✅ Build Application
✅ Run Tests (with coverage reports)
✅ Static Code Analysis (SonarQube)
✅ Quality Gate (MUST PASS)
✅ Security Scanning (OWASP + Trivy, fails on HIGH/CRITICAL)
✅ Build Docker Image (tag: prod-{VERSION}, prod-{TIMESTAMP}, latest)
✅ Push to Registry
```

**Purpose**: Production deployment  
**Duration**: ~15-20 minutes  
**Artifacts**: All reports + Docker image with version tags

---

## Troubleshooting

### Jenkins Won't Start

```bash
# Check logs
docker logs jenkins

# Check if port 8080 is in use
lsof -i :8080  # Mac/Linux
netstat -ano | findstr :8080  # Windows

# Restart Jenkins
docker-compose restart jenkins
```

### SonarQube Connection Failed

```bash
# Check SonarQube is running
docker-compose ps sonarqube

# Check SonarQube logs
docker logs sonarqube

# Wait for SonarQube to fully start (can take 2-3 minutes)
docker logs sonarqube | grep "SonarQube is operational"
```

### Docker Registry Push Failed

```bash
# Check registry is running
curl http://localhost:5000/v2/

# Check Jenkins can access Docker socket
docker exec -it jenkins docker ps

# Restart registry
docker-compose restart registry
```

### OWASP Scan Taking Too Long

```bash
# Add NVD API key (speeds up from 30min to 2min)
# Get key: https://nvd.nist.gov/developers/request-an-api-key
# Add in Jenkins: Manage Jenkins → Credentials → Add
# ID: nvd-api-key
# Type: Secret text
```

### Out of Memory

```bash
# Check Docker memory allocation
docker stats

# Increase Docker memory limit (Docker Desktop):
# Settings → Resources → Memory → 8GB minimum
```

---

## Security Best Practices

### Implemented
- ✅ No secrets in repository
- ✅ Credentials stored in Jenkins credential store
- ✅ Registry authentication configured
- ✅ OWASP dependency scanning
- ✅ Trivy container scanning
- ✅ SonarQube quality gates

### Recommended Improvements
- [ ] Enable HTTPS on Docker registry
- [ ] Use external secret management (Vault)
- [ ] Implement image signing
- [ ] Add SAST scanning (Snyk/Checkmarx)
- [ ] Enable branch protection rules
- [ ] Implement approval gates for prod

---

## Summary

This platform platform is now running with:
- ✅ Jenkins CI/CD with automated pipelines
- ✅ Docker registry for image storage
- ✅ SonarQube for code quality
- ✅ OWASP + Trivy for security
- ✅ Prometheus + Grafana for metrics
- ✅ Loki for log aggregation
- ✅ Alertmanager for alerts
- ✅ Full observability stack

**Support**:

- View logs: `docker-compose logs -f <service-name>`
- Restart service: `docker-compose restart <service-name>`
- Stop all: `docker-compose down`
- Start all: `docker-compose up -d`
