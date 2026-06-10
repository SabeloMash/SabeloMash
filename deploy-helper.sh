#!/bin/bash
# CCTECH Store Repository Viewer - Deployment Helper Script
# This script helps prepare the environment and deploy the webapp

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  CCTECH Store Repository Viewer - Deployment Tool  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration variables (customize as needed)
APP_DIR="/var/www/html/cctech-store-repo"
ANSIBLE_USER="ansible"
DEPLOYMENT_HOSTS="${1:-all}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"

# Function to check if running as root or with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then 
        echo -e "${RED}✗ This script needs sudo privileges${NC}"
        echo "  Run with: sudo bash deploy.sh"
        exit 1
    fi
    echo -e "${GREEN}✓ Sudo privileges verified${NC}"
}

# Function to check dependencies
check_dependencies() {
    echo ""
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    local missing=0
    
    for cmd in ansible python3; do
        if command -v $cmd &> /dev/null; then
            echo -e "${GREEN}✓ $cmd found${NC}"
        else
            echo -e "${RED}✗ $cmd not found${NC}"
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        echo -e "${RED}✗ Missing $missing dependencies${NC}"
        echo "  Install with: sudo apt-get install ansible python3"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All dependencies found${NC}"
}

# Function to validate GitLab token
validate_gitlab_token() {
    echo ""
    echo -e "${YELLOW}Validating GitLab token...${NC}"
    
    if [ -z "$GITLAB_TOKEN" ]; then
        echo -e "${YELLOW}⚠ GitLab token not set${NC}"
        echo "  Set with: export GITLAB_TOKEN=glpat-xxxxxxxxxxxx"
        read -p "  Enter GitLab token: " GITLAB_TOKEN
    fi
    
    if [ -z "$GITLAB_TOKEN" ]; then
        echo -e "${RED}✗ No GitLab token provided${NC}"
        echo "  You can skip this, but API features will be limited"
    else
        echo -e "${GREEN}✓ GitLab token configured${NC}"
    fi
}

# Function to generate inventory file
generate_inventory() {
    echo ""
    echo -e "${YELLOW}Setting up inventory...${NC}"
    
    local inventory_file="inventory.ini"
    
    if [ ! -f "$inventory_file" ]; then
        echo -e "${YELLOW}Creating inventory file: $inventory_file${NC}"
        cat > "$inventory_file" << EOF
[all]
# Add your store servers here:
# teststore3.cctech.local
# teststore4.cctech.local
# Example:
# [stores]
# teststore3.cctech.local
# teststore4.cctech.local
#
# [stores:vars]
# ansible_user=ansible
# ansible_sudo_pass=your_sudo_password

localhost ansible_connection=local

[stores:vars]
ansible_user=$ANSIBLE_USER
ansible_ssh_private_key_file=~/.ssh/cctech_deploy_key
EOF
        echo -e "${GREEN}✓ Created $inventory_file${NC}"
        echo -e "${YELLOW}  Please edit $inventory_file and add your store servers${NC}"
    else
        echo -e "${GREEN}✓ Using existing $inventory_file${NC}"
    fi
}

# Function to show deployment command
show_deployment_command() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Deployment Command:${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ -n "$GITLAB_TOKEN" ]; then
        echo -e "${YELLOW}With GitLab token:${NC}"
        echo "ansible-playbook Webapp.yml \\"
        echo "  -i inventory.ini \\"
        echo "  -e \"git_admin_token=$GITLAB_TOKEN\" \\"
        echo "  -u $ANSIBLE_USER"
    else
        echo -e "${YELLOW}Without GitLab token (API features disabled):${NC}"
        echo "ansible-playbook Webapp.yml \\"
        echo "  -i inventory.ini \\"
        echo "  -u $ANSIBLE_USER"
    fi
    
    echo ""
    echo -e "${YELLOW}Or for a single store:${NC}"
    echo "ansible-playbook Webapp.yml \\"
    echo "  -i inventory.ini \\"
    echo "  -e \"git_admin_token=$GITLAB_TOKEN\" \\"
    echo "  -u $ANSIBLE_USER \\"
    echo "  --limit teststore3.cctech.local"
}

# Function to create local test environment
create_test_env() {
    echo ""
    read -p "Create local test environment? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Setting up local test environment...${NC}"
        
        # Create test directory structure
        mkdir -p "$APP_DIR"
        echo -e "${GREEN}✓ Created $APP_DIR${NC}"
        
        # Copy files (adjust path as needed)
        if [ -f "Webapp.yml" ]; then
            echo -e "${YELLOW}Note: Run the actual playbook with ansible-playbook${NC}"
        fi
    fi
}

# Function to verify deployment
verify_deployment() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Verification Commands:${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}After deployment, verify with:${NC}"
    echo ""
    echo "# Check Apache status:"
    echo "sudo systemctl status apache2"
    echo ""
    echo "# Test API locally:"
    echo "curl http://localhost/api.php?action=get_repo_info"
    echo ""
    echo "# Check Apache logs:"
    echo "sudo tail -f /var/log/apache2/cctech-store-repo-*.log"
    echo ""
    echo "# Test PHP:"
    echo "php -r 'echo gethostname();'"
}

# Main execution
main() {
    echo ""
    check_sudo
    check_dependencies
    validate_gitlab_token
    generate_inventory
    create_test_env
    show_deployment_command
    verify_deployment
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Setup complete! Ready to deploy.${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# Run main function
main
