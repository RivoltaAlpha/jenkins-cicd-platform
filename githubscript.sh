#!/bin/bash

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       GitHub Integration Setup for Jenkins                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Check if git is configured
if ! git config user.name > /dev/null 2>&1; then
    print_warning "Git user not configured"
    read -p "Enter your Git name: " git_name
    git config user.name "$git_name"
fi

if ! git config user.email > /dev/null 2>&1; then
    print_warning "Git email not configured"
    read -p "Enter your Git email: " git_email
    git config user.email "$git_email"
fi

print_success "Git configured: $(git config user.name) <$(git config user.email)>"
echo ""

# Check if already initialized
if [ ! -d .git ]; then
    print_info "Initializing Git repository..."
    git init
    print_success "Git repository initialized"
else
    print_info "Git repository already initialized"
fi
echo ""

# Check for remote
if git remote | grep -q "^origin$"; then
    current_remote=$(git remote get-url origin 2>&1)
    if [[ "$current_remote" =~ ^(https://|git@).+ ]] && [[ ! "$current_remote" =~ (fatal|error) ]]; then
        print_info "Current remote: $current_remote"
        read -p "Update remote? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            while true; do
                read -p "Enter new GitHub repository URL: " repo_url
                if [ -z "$repo_url" ]; then
                    print_error "URL cannot be empty. Please try again."
                else
                    git remote set-url origin "$repo_url"
                    print_success "Remote updated to: $repo_url"
                    break
                fi
            done
        fi
    else
        print_error "Remote exists but URL is invalid or empty"
        print_info "Please configure a valid GitHub repository URL"
        while true; do
            read -p "Enter GitHub repository URL: " repo_url
            if [ -z "$repo_url" ]; then
                print_error "URL cannot be empty. Please try again."
            else
                git remote set-url origin "$repo_url"
                print_success "Remote updated to: $repo_url"
                break
            fi
        done
    fi
else
    print_info "No remote configured"
    while true; do
        read -p "Enter GitHub repository URL (https://github.com/username/repo.git): " repo_url
        if [ -z "$repo_url" ]; then
            print_error "URL cannot be empty. Please try again."
        else
            git remote add origin "$repo_url"
            print_success "Remote added: $repo_url"
            break
        fi
    done
fi
echo ""

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    print_info "Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Node modules
node_modules/
npm-debug.log

# Test coverage
coverage/
*.lcov
junit.xml

# Security reports
trivy-report.json
dependency-check-report/

# IDE
.vscode/
.idea/

# OS
.DS_Store

# Environment
.env
.env.local

# Backups
backups/
*.tar.gz
EOF
    print_success ".gitignore created"
fi

# Initial commit
if ! git rev-parse HEAD > /dev/null 2>&1; then
    print_info "Creating initial commit..."
    git add .
    git commit -m "Initial commit - Jenkins CI/CD Platform"
    print_success "Initial commit created"
else
    print_info "Repository already has commits"
fi
echo ""

# Create and push branches
echo "Creating branches..."
branches=("develop" "test" "prod")

for branch in "${branches[@]}"; do
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        print_info "Branch '$branch' already exists"
    else
        git checkout -b "$branch" 2>/dev/null || git checkout "$branch"
        print_success "Branch '$branch' created"
    fi
done

# Return to main/master
if git show-ref --verify --quiet refs/heads/main; then
    git checkout main
elif git show-ref --verify --quiet refs/heads/master; then
    git checkout master
else
    git checkout -b main
fi

echo ""
print_info "Ready to push to GitHub"
echo ""
read -p "Push all branches to GitHub now? [y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Pushing branches..."
    
    # Get current branch name
    current_branch=$(git branch --show-current)
    
    # Push current branch first
    git push -u origin "$current_branch" || print_warning "Failed to push $current_branch (may already exist)"
    
    # Push other branches
    for branch in "${branches[@]}"; do
        git push -u origin "$branch" || print_warning "Failed to push $branch (may already exist)"
    done
    
    echo ""
    print_success "All branches pushed to GitHub!"
else
    print_info "Skipped push. You can push later with:"
    echo "  git push -u origin $(git branch --show-current)"
    echo "  git push -u origin develop"
    echo "  git push -u origin test"
    echo "  git push -u origin prod"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       Next Steps                                               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "1. Configure Jenkins job with your GitHub repo:"
echo "   • Go to http://localhost:8080"
echo "   • Click 'microservice-pipeline' → 'Configure'"
echo "   • Update Git repository URL"
echo ""
echo "2. Add GitHub webhook (for automatic builds):"
echo "   • Go to your GitHub repo → Settings → Webhooks"
echo "   • Add webhook: http://YOUR_SERVER_IP:8080/github-webhook/"
echo "   • Content type: application/json"
echo "   • Events: Just the push event"
echo ""
echo "3. For private repos, add credentials in Jenkins:"
echo "   • Manage Jenkins → Manage Credentials"
echo "   • Add Username/Password or SSH key"
echo ""
echo "4. Test the pipeline:"
echo "   • Make a change and push to develop branch"
echo "   • Watch Jenkins automatically build!"
echo ""
echo "For local development, consider using ngrok:"
echo "  brew install ngrok  # or download from ngrok.com"
echo "  ngrok http 8080"
echo "  Use ngrok URL in GitHub webhook"
echo ""
print_success "GitHub integration setup complete!"
echo ""
echo ""
read -p "Press Enter to close..."
echo ""