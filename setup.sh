#!/bin/bash

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       Jenkins CI/CD Platform Setup                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi
print_success "Docker is installed"

# Check Docker Compose
if ! command -v docker compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
print_success "Docker Compose is installed"

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker first."
    exit 1
fi
print_success "Docker daemon is running"

echo ""

# Create necessary directories
echo "Creating directories..."
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards
mkdir -p prometheus
mkdir -p loki
mkdir -p app/src
mkdir -p app/tests
mkdir -p jenkins

print_success "Directories created"
echo ""

# Check for port conflicts
echo "Checking for port conflicts..."
ports=(8080 9000 3000 5000 9090 9093 3100)
port_names=("Jenkins" "SonarQube" "Grafana" "Docker Registry" "Prometheus" "Alertmanager" "Loki")
conflicts=0

for i in "${!ports[@]}"; do
    port=${ports[$i]}
    name=${port_names[$i]}
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        print_error "Port $port is already in use (needed for $name)"
        conflicts=$((conflicts + 1))
    fi
done

if [ $conflicts -gt 0 ]; then
    echo ""
    print_error "$conflicts port(s) are already in use. Please free them or modify docker-compose.yml"
    echo ""
    print_info "You can check what's using a port with: sudo lsof -i :<port>"
    exit 1
fi

print_success "All required ports are available"
echo ""

# Pull required Docker images
echo "Pulling Docker images (this may take a few minutes)..."
docker compose pull

print_success "Docker images pulled"
echo ""

# Build custom Jenkins image
echo "Building Jenkins image..."
docker compose build jenkins

print_success "Jenkins image built"
echo ""

# Start the stack
echo "Starting services..."
docker compose up -d

print_success "Services started"
echo ""

# Wait for services to be healthy
echo "Waiting for services to initialize..."
echo "This may take 2-3 minutes..."
echo ""

# Function to check if a service is healthy
check_service() {
    local service=$1
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker compose ps $service | grep -q "healthy\|running"; then
            return 0
        fi
        sleep 5
        attempt=$((attempt + 1))
        echo -n "."
    done
    
    return 1
}

# Wait for Jenkins
echo -n "Waiting for Jenkins"
if check_service jenkins; then
    echo ""
    print_success "Jenkins is ready"
else
    echo ""
    print_error "Jenkins failed to start. Check logs with: docker compose logs jenkins"
    exit 1
fi

# Wait for SonarQube
echo -n "Waiting for SonarQube"
if check_service sonarqube; then
    echo ""
    print_success "SonarQube is ready"
else
    echo ""
    print_error "SonarQube failed to start. Check logs with: docker compose logs sonarqube"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              Setup Complete!                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Access your services:"
echo ""
echo "  Jenkins:          http://localhost:8080"
echo "                    Username: admin"
echo "                    Password: admin123"
echo ""
echo "  SonarQube:        http://localhost:9000"
echo "                    Username: admin"
echo "                    Password: admin123"
echo "                    (Change on first login)"
echo ""
echo "  Grafana:          http://localhost:3000"
echo "                    Username: admin"
echo "                    Password: admin123"
echo ""
echo "  Prometheus:       http://localhost:9090"
echo "  Alertmanager:     http://localhost:9093"
echo "  Docker Registry:  http://localhost:5000"
echo ""
echo "Next steps:"
echo ""
echo "  OPTION A - Quick Start (No Git Required):"
echo "    1. Access Jenkins at http://localhost:8080"
echo "    2. Click 'microservice-pipeline' job"
echo "    3. Click 'Scan Multibranch Pipeline Now'"
echo "    4. Manually trigger builds for testing"
echo ""
echo "  OPTION B - GitHub Integration (Recommended):"
echo "    1. Push code to GitHub"
echo "    2. Update Jenkins job with your repo URL"
echo "    3. Add webhook for automatic builds"
echo "    4. See GIT_SETUP.md for detailed instructions"
echo ""
echo "  OPTION C - Local Git Server:"
echo "    1. See GIT_SETUP.md for Docker-based Git server setup"
echo "    2. Full Git workflow without external dependencies"
echo ""
echo "Useful commands:"
echo ""
echo "  View logs:        docker compose logs -f [service]"
echo "  Stop services:    docker compose down"
echo "  Restart:          docker compose restart [service]"
echo "  Remove all data:  docker compose down -v"
echo ""
print_success "Happy CI/CD-ing! 🚀"
echo ""
echo ""
read -p "Press Enter to close..."
echo ""