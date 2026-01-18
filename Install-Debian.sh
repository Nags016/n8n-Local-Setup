#!/bin/bash

# ============================================
# n8n Local Setup Script - Debian-based Linux
# ============================================
# For: Ubuntu, Pop!_OS, Linux Mint, Debian
# Author: Nagaraj Bhat
# License: MIT
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    exit 1
fi

print_header "n8n Installation Script for Debian-based Linux"

# Check internet connection
print_info "Checking internet connection..."
if ping -c 1 google.com &> /dev/null; then
    print_success "Internet connection OK"
else
    print_error "No internet connection. Please check your network."
    exit 1
fi

# Update system
print_header "Step 1: Updating System"
print_info "Updating package database..."
sudo apt update
sudo apt upgrade -y
print_success "System updated"

# Install prerequisites
print_header "Step 2: Installing Prerequisites"
print_info "Installing required packages..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common
print_success "Prerequisites installed"

# Install Docker
print_header "Step 3: Installing Docker"
if command -v docker &> /dev/null; then
    print_warning "Docker is already installed"
    docker --version
else
    print_info "Adding Docker's official GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    print_info "Setting up Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    print_info "Installing Docker Engine..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    print_success "Docker installed successfully"
fi

# Install docker-compose if not available
if ! command -v docker-compose &> /dev/null; then
    print_info "Installing docker-compose..."
    sudo apt install -y docker-compose
    print_success "docker-compose installed"
fi

# Start and enable Docker
print_info "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker
print_success "Docker service started and enabled"

# Add user to docker group
print_header "Step 4: Configuring Docker Permissions"
if groups $USER | grep &>/dev/null '\bdocker\b'; then
    print_warning "User already in docker group"
else
    print_info "Adding $USER to docker group..."
    sudo usermod -aG docker $USER
    print_success "User added to docker group"
    print_warning "You may need to log out and log back in for group changes to take effect"
fi

# Verify Docker installation
print_header "Step 5: Verifying Docker Installation"
if docker --version &> /dev/null; then
    print_success "Docker version: $(docker --version)"
else
    print_error "Docker installation verification failed"
    exit 1
fi

if docker-compose --version &> /dev/null; then
    print_success "Docker Compose version: $(docker-compose --version)"
else
    print_error "Docker Compose installation verification failed"
    exit 1
fi

# Test Docker (skip if not in docker group yet)
if groups | grep -q docker; then
    print_info "Testing Docker installation..."
    if docker run hello-world &> /dev/null; then
        print_success "Docker is working correctly"
    else
        print_warning "Docker test failed, but installation seems OK. Try after re-login."
    fi
else
    print_warning "Cannot test Docker yet. Please log out and back in, then run: docker run hello-world"
fi

# Create n8n directory
print_header "Step 6: Setting up n8n Directory"
N8N_DIR="$HOME/.n8n"
if [ -d "$N8N_DIR" ]; then
    print_warning "n8n directory already exists at $N8N_DIR"
    read -p "Do you want to use existing directory? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Creating backup of existing directory..."
        mv "$N8N_DIR" "$N8N_DIR.backup.$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$N8N_DIR"
        print_success "Backup created and new directory set up"
    fi
else
    mkdir -p "$N8N_DIR"
    print_success "Created n8n directory at $N8N_DIR"
fi

# Download docker-compose.yml
print_header "Step 7: Creating Docker Compose Configuration"
cd "$N8N_DIR"

# Check if docker-compose.yml exists
if [ -f "docker-compose.yml" ]; then
    print_warning "docker-compose.yml already exists"
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv docker-compose.yml docker-compose.yml.backup
        print_info "Existing file backed up"
    else
        print_info "Keeping existing docker-compose.yml"
    fi
fi

# Create docker-compose.yml if it doesn't exist or was backed up
if [ ! -f "docker-compose.yml" ]; then
    print_info "Creating docker-compose.yml..."
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=changeme123
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=America/New_York
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
      - N8N_LOG_LEVEL=info
    volumes:
      - ~/.n8n:/home/node/.n8n
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
EOF
    print_success "docker-compose.yml created"
    print_warning "⚠️  IMPORTANT: Change the password and timezone in docker-compose.yml!"
    print_info "Edit the file: nano $N8N_DIR/docker-compose.yml"
fi

# Pull Docker image
print_header "Step 8: Downloading n8n Docker Image"
print_info "This may take a few minutes..."

# Handle case where user might not be in docker group yet
if groups | grep -q docker; then
    docker-compose pull
    print_success "n8n Docker image downloaded"
else
    print_warning "Cannot pull image yet - not in docker group"
    print_info "After re-login, run: cd ~/.n8n && docker-compose pull"
fi

# Start n8n
print_header "Step 9: Starting n8n"
if groups | grep -q docker; then
    docker-compose up -d
    print_success "n8n started successfully"
    
    # Wait for n8n to be ready
    print_info "Waiting for n8n to initialize..."
    sleep 10
    
    # Check if n8n is running
    if docker ps | grep -q n8n; then
        print_success "n8n is running!"
    else
        print_error "n8n failed to start. Check logs with: docker-compose logs"
    fi
else
    print_warning "Cannot start n8n yet - not in docker group"
    print_info "After re-login, run: cd ~/.n8n && docker-compose up -d"
fi

# Create systemd service (optional)
print_header "Step 10: Setting up Auto-start (Optional)"
read -p "Do you want n8n to start automatically on boot? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Creating systemd service..."
    
    # Find docker-compose path
    DOCKER_COMPOSE_PATH=$(which docker-compose)
    
    sudo tee /etc/systemd/system/n8n-docker.service > /dev/null << EOF
[Unit]
Description=n8n Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$N8N_DIR
ExecStart=$DOCKER_COMPOSE_PATH up -d
ExecStop=$DOCKER_COMPOSE_PATH down
User=$USER

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable n8n-docker.service
    print_success "Auto-start configured"
fi

# Print completion message
print_header "Installation Complete! 🎉"
echo -e "${GREEN}n8n installation finished!${NC}\n"

if groups | grep -q docker; then
    echo -e "${GREEN}n8n is running!${NC}\n"
    echo -e "${BLUE}Access n8n at:${NC} ${YELLOW}http://localhost:5678${NC}\n"
else
    echo -e "${YELLOW}Please log out and log back in to complete setup${NC}\n"
    echo -e "${BLUE}After re-login, start n8n with:${NC}"
    echo -e "  ${YELLOW}cd ~/.n8n && docker-compose up -d${NC}\n"
    echo -e "${BLUE}Then access n8n at:${NC} ${YELLOW}http://localhost:5678${NC}\n"
fi

echo -e "${BLUE}Default credentials:${NC}"
echo -e "  Username: ${YELLOW}admin${NC}"
echo -e "  Password: ${YELLOW}changeme123${NC} ${RED}(CHANGE THIS!)${NC}\n"
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  Start:   ${YELLOW}cd ~/.n8n && docker-compose up -d${NC}"
echo -e "  Stop:    ${YELLOW}cd ~/.n8n && docker-compose down${NC}"
echo -e "  Logs:    ${YELLOW}cd ~/.n8n && docker-compose logs -f${NC}"
echo -e "  Restart: ${YELLOW}cd ~/.n8n && docker-compose restart${NC}"
echo -e "  Update:  ${YELLOW}cd ~/.n8n && docker-compose pull && docker-compose up -d${NC}\n"
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Edit settings: ${YELLOW}nano ~/.n8n/docker-compose.yml${NC}"
echo -e "  Change timezone in GENERIC_TIMEZONE variable\n"
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. ${RED}Change the default password${NC} in ~/.n8n/docker-compose.yml"
echo -e "  2. Set your timezone in docker-compose.yml"
echo -e "  3. Restart n8n: cd ~/.n8n && docker-compose restart"
echo -e "  4. Open http://localhost:5678 in your browser"
echo -e "  5. Read the documentation at https://docs.n8n.io\n"
echo -e "${GREEN}Happy automating! 🚀${NC}\n"

# Final reminder about group
if ! groups | grep -q docker; then
    print_warning "IMPORTANT: Log out and log back in for Docker permissions to take effect!"
    print_info "Alternative: Run 'newgrp docker' in this terminal"
fi
