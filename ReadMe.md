# Jenkins CI/CD Pipeline Setup Guide

## Overview
This guide walks you through setting up a complete Jenkins Multibranch Pipeline with branch-specific build rules, security scanning, and container registry integration.

## Pipeline Requirements

### Branch-Specific Rules
- **develop**: Build + Test + Static Analysis (no registry push)
- **test**: Build + Test + Static Analysis + Security Scans + Push to Registry
- **prod**: Build + Test + Static Analysis + Security Scans + Push with Release Tags

## Quick Start

### Step 1: Start the Infrastructure
```bash
# Start all services
docker-compose up -d

# Wait for Jenkins to be ready (takes ~2 minutes)
docker logs -f jenkins
# Wait for: "Jenkins is fully up and running"
```

### Step 2: Access Jenkins
1. Open: http://localhost:8080
2. Login credentials:
   - **Username**: `admin`
   - **Password**: `admin123`

### Step 3: Create Branches

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

# Return to master
git checkout master
```

### Step 4: Setup GitHub Repository (Optional)

If using GitHub:
```bash
# Add remote
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push all branches
git push -u origin master develop test prod
```

### Step 5: Create Jenkins Multibranch Pipeline Via Jenkins UI 

1. Click **"New Item"** in Jenkins
2. Enter name: `microservice-pipeline`
3. Select **"Multibranch Pipeline"**
4. Click **OK**

5. **Branch Sources** section:
   - Click **"Add source"** → **"Git"**
   - **Project Repository**: 
     - For local: `/var/jenkins_home/workspace` (auto-detected)
     - For GitHub: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
   
6. **Build Configuration**:
   - **Mode**: by Jenkinsfile
   - **Script Path**: `Jenkinsfile`

7. **Scan Multibranch Pipeline Triggers**:
   - ✅ Check **"Periodically if not otherwise run"**
   - **Interval**: 1 minute (for testing) or 5 minutes (production)

8. Click **"Save"**

9. Click **"Scan Repository Now"** to discover branches

## Credentials Setup

The init.groovy script automatically creates these credentials:

### 1. Docker Registry Credentials
- **ID**: `docker-registry-credentials`
- **Type**: Username with password
- **Username**: `admin`
- **Password**: `admin`
- **Usage**: Authenticating to local Docker registry

### 2. SonarQube Token
- **ID**: `sonarqube-token`
- **Type**: Secret text
- **Value**: Auto-generated SonarQube token
- **Usage**: Static code analysis

### 3. NVD API Key (Optional but HIGHLY Recommended)
- **ID**: `nvd-api-key`
- **Type**: Secret text
- **Value**: Your NVD API key
- **Usage**: Speeds up OWASP Dependency Check (from 30+ min to <2 min)

**To get an NVD API key:**
1. Go to https://nvd.nist.gov/developers/request-an-api-key
2. Fill out the form and submit
3. You'll receive an API key via email instantly
4. Add it to Jenkins:
   - **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
   - **Add Credentials** → **Secret text**
   - Paste your API key
   - ID: **nvd-api-key**
   - Click **Create**

**Without NVD API key**: The OWASP scan will use `--noupdate` flag (faster but may miss recent vulnerabilities)

### 4. Dependency-Track API Key (Optional, needed for continuous SBOM tracking)
- **ID**: `dependency-track-api-key`
- **Type**: Secret text
- **Usage**: Publishing the Syft-generated CycloneDX SBOM to Dependency-Track after each test/prod build

Dependency-Track can't be pre-seeded with this key the way SonarQube's token is, because it requires an initial login before any team/API key exists:

1. Start the stack and open http://localhost:8092 (frontend)
2. Log in with the default `admin` / `admin` and set a new password when prompted
3. Go to **Administration → Access Management → Teams**, open the default **Automation** team (or create one)
4. Under **API Keys**, click **+** to generate a key, then grant it `BOM_UPLOAD` and `PROJECT_CREATION_UPLOAD` permissions
5. Add it to Jenkins the same way as the NVD key above, using ID **dependency-track-api-key**

**Without this credential**: The `Generate & Publish SBOM` stage still generates and archives `sbom.json`, it just skips the upload with a warning.

### Manual Credential Update (if needed):
1. Go to **Manage Jenkins** → **Credentials**
2. Click **"(global)"** domain
3. Click on credential ID
4. Click **"Update"**
5. Enter new values
6. Click **"Save"**

## Understanding the Pipeline

### Pipeline Stages Overview

``` bash
┌─────────────┐
│ Push Code   │  Any Branch
└──────┬──────┘
       │
┌──────▼──────────┐
│ Secret Scanning │  All Branches (Gitleaks)
└──────┬──────────┘
       │
┌──────▼──────┐
│    Build    │  All Branches will do this
└──────┬──────┘
       │
┌──────▼──────┐
│  Run Tests  │  All Branches will do this
└──────┬──────┘
       │
┌──────▼──────────┐
│ Static Analysis │  All Branches will do this (SonarQube)
└──────┬──────────┘
       │
       ├─── develop: STOP HERE ───┐
       │                          │
       │  test/prod: Continue     │
       │                          │
┌──────▼────────────┐             │
│ Security Scanning │             │
│  - Dependency     │             │
│  - Container      │             │
│  - IaC (Checkov)  │             │
│  - Final Secrets  │             │
└──────┬────────────┘             │
       │                          │
┌──────▼──────────┐               │
│  Build Image    │               │
└──────┬──────────┘               │
       │                          │
┌──────▼──────────────┐           │
│ Generate & Publish  │           │
│ SBOM (Syft +        │           │
│ Dependency-Track)   │           │
└──────┬──────────────┘           │
       │                          │
┌──────▼──────────┐               │
│  Push Registry  │               │
└──────┬──────────┘               │
       │                          │
┌──────▼──────────┐               │
│ Deploy Info     │               │
└─────────────────┘               │
                                  │
                           ┌──────▼──────┐
                           │   Success   │
                           └─────────────┘
```

### Branch-Specific Behavior

#### Develop Branch

```bash
✓ Checkout
✓ Secret Scanning (Gitleaks, non-blocking)
✓ Build Application
✓ Run Tests
✓ Static Code Analysis
✗ Security Scanning (skipped)
✗ Build Docker Image (skipped)
✗ Generate & Publish SBOM (skipped)
✗ Push to Registry (skipped)
```

#### Test Branch

```bash
✓ Checkout
✓ Secret Scanning (Gitleaks)
✓ Build Application
✓ Run Tests
✓ Static Code Analysis
✓ Security Scanning (OWASP + Trivy + Checkov + final Gitleaks pass)
✓ Build Docker Image (tag: test-{BUILD_NUMBER})
✓ Generate & Publish SBOM (Syft → Dependency-Track)
✓ Push to Registry
```

#### Prod Branch

```bash
✓ Checkout
✓ Secret Scanning (Gitleaks, blocking)
✓ Build Application
✓ Run Tests
✓ Static Code Analysis
✓ Quality Gate (must pass)
✓ Security Scanning (OWASP + Trivy, fail on HIGH/CRITICAL; Checkov + final Gitleaks pass, fail on findings)
✓ Build Docker Image (tag: prod-{VERSION})
✓ Generate & Publish SBOM (Syft → Dependency-Track)
✓ Push to Registry (with 'latest' tag)
```

## 🧪 Testing the Pipeline

### Test Develop Branch

```bash
git checkout develop

# Make a change
>> app/src/index.ts

git add .
git commit -m "test: develop branch pipeline"
git push origin develop
```

**Expected**: Build, test, and static analysis only. No image push.

### Test Test Branch

```bash
git checkout test
git merge develop

git push origin test
```

**Expected**: Full pipeline with security scans and registry push with tag `test-{BUILD_NUMBER}`

### Test Prod Branch

```bash
git checkout prod

# Update version in package.json
cd app
npm version patch  # or minor, major

cd ..
git add .
git commit -m "chore: bump version for release"
git push origin prod
```

**Expected**: Full pipeline with quality gate + security scans + registry push with version tag and 'latest'

## 🔍 Viewing Build Results

### 1. Console Output

- Click on build number
- Click **"Console Output"**
- See real-time logs

### 2. Test Results

- Click on build
- Click **"Test Result"**
- View JUnit test reports

### 3. Code Coverage

- Click on build
- Click **"Coverage Report"**
- View Istanbul/NYC coverage

### 4. Security Reports

- Click on build
- Click **"OWASP Dependency Check"**
- Download **"Trivy Report"** from artifacts

### 5. SonarQube Analysis

- Open: http://localhost:9000
- Login: `admin` / `admin`
- View project: `microservice-app`

## 🐳 Verifying Registry Images

### List Images in Registry

```bash

# Check registry catalog
curl http://localhost:5000/v2/_catalog

# Check specific image tags
curl http://localhost:5000/v2/microservice-app/tags/list
```

### Pull and Run Image

```bash
# Test branch image
docker pull registry:5000/microservice-app:test-1

# Prod branch image
docker pull registry:5000/microservice-app:latest

# Run container
docker run -p 3000:3000 registry:5000/microservice-app:latest
```

## 📈 Monitoring

### Prometheus Metrics

- Jenkins: http://localhost:8080/prometheus/
- Prometheus UI: http://localhost:9090
- Example queries:
  - Total builds: `default_jenkins_builds_total_build_count_total`
  - Success rate: `default_jenkins_builds_success_build_count_total`
  - Failed builds: `default_jenkins_builds_failed_build_count_total`
  - Build duration: `default_jenkins_builds_duration_milliseconds_summary`

### Grafana Dashboards

- URL: http://localhost:3000
- Login: `admin` / `admin123`
- Dashboard: "Jenkins Performance"

## 🛠️ Troubleshooting

### Issue: Pipeline doesn't trigger

**Solution**: 
```bash
# Manually trigger scan
# In Jenkins UI: Click "Scan Repository Now"
```

### Issue: SonarQube connection fails
**Solution**:
```bash
# Check SonarQube is running
docker ps | grep sonarqube

# Check SonarQube logs
docker logs sonarqube

# Regenerate token
docker exec -it jenkins cat /var/jenkins_home/credentials.xml
```

### Issue: Docker registry push fails
**Solution**:
```bash
# Check registry is running
docker ps | grep registry

# Test registry manually
curl http://localhost:5000/v2/

# Check Jenkins has Docker socket access
docker exec -it jenkins docker ps
```

### Issue: Git credentials in Jenkins
**Solution**:
```bash
# For private repos, add GitHub credentials
# Manage Jenkins → Credentials → Add Credentials
# Kind: Username with password
# Username: your-github-username
# Password: your-github-personal-access-token
```

## 🔒 Security Best Practices

### ✅ Current Security Measures
- ✓ No secrets in repository
- ✓ Credentials stored in Jenkins credential store
- ✓ Registry authentication required
- ✓ Secret scanning (Gitleaks) - CI pass on every commit, final pass before deploy
- ✓ OWASP dependency scanning
- ✓ Container vulnerability scanning (Trivy)
- ✓ IaC scanning (Checkov) on the Dockerfiles
- ✓ SonarQube code quality + SAST checks
- ✓ CycloneDX SBOM generation (Syft) + continuous vulnerability tracking (Dependency-Track)

### 🔄 Recommended Improvements
- [ ] Use HashiCorp Vault for secrets
- [ ] Enable HTTPS on registry
- [ ] Implement image signing
- [ ] Enable branch protection rules
- [ ] Implement approval gates for prod
- [ ] Add DAST (OWASP ZAP) against a running staging deployment

## 📚 Additional Resources

### Jenkins Documentation
- [Multibranch Pipeline](https://www.jenkins.io/doc/book/pipeline/multibranch/)
- [Credentials Plugin](https://plugins.jenkins.io/credentials/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)

### Tool Documentation
- [SonarQube](https://docs.sonarqube.org/)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)
- [Trivy](https://aquasecurity.github.io/trivy/)
- [Gitleaks](https://github.com/gitleaks/gitleaks)
- [Checkov](https://www.checkov.io/)
- [Syft](https://github.com/anchore/syft)
- [Dependency-Track](https://docs.dependencytrack.org/)

## 🎓 Next Steps

1. ✅ Start infrastructure
2. ✅ Access Jenkins (http://localhost:8080)
3. ✅ Create multibranch pipeline
4. ✅ Create and push branches (develop, test, prod)
5. ✅ Trigger builds on each branch
6. ✅ Verify images in registry
7. ✅ Check monitoring dashboards

## 📝 Summary

Your Jenkins CI/CD pipeline is now configured with:
- ✓ Automated multibranch pipeline
- ✓ Branch-specific build rules
- ✓ Secure credential management
- ✓ Comprehensive security scanning
- ✓ Container registry integration
- ✓ Quality gates for production
- ✓ Full monitoring and reporting

**Ready to deliver! 🚀**
