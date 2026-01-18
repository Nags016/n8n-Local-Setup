#  n8n Local Setup Guide

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![n8n](https://img.shields.io/badge/n8n-latest-orange)](https://n8n.io)
[![Docker](https://img.shields.io/badge/Docker-supported-blue)](https://www.docker.com/)

> **Complete guide to set up n8n workflow automation locally on Linux - 100% Free & Open Source**

n8n is a powerful workflow automation tool that you can run entirely on your own machine, with no subscription fees or cloud dependencies.

##  Table of Contents

- [What is n8n?](#what-is-n8n)
- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
- [Arch-based Linux (Garuda, Manjaro, EndeavourOS)](#arch-based-installation)
- [Debian-based Linux (Ubuntu, Pop!_OS, Linux Mint)](#debian-based-installation)
- [Post-Installation Setup](#post-installation-setup)
- [Usage Guide](#usage-guide)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

##  What is n8n?

n8n (pronounced "n-eight-n") is a free, open-source workflow automation tool that lets you connect different apps and services together. Think of it as a self-hosted alternative to Zapier or Make.com, but completely free!

**Key Features:**
-  300+ integrations (Google Sheets, Discord, Slack, GitHub, etc.)
-  Self-hosted - your data never leaves your machine
-  100% free and open-source
-  Visual workflow editor
- Supports complex workflows with branching and loops

---

## 💻 System Requirements

### Minimum Requirements
- **CPU:** 2 cores
- **RAM:** 2GB
- **Storage:** 5GB free space
- **OS:** Any modern Linux distribution

### Recommended
- **CPU:** 4+ cores
- **RAM:** 4GB+
- **Storage:** 10GB+ free space
- **Network:** Internet connection for downloading packages

**Tested on:**
- ✅ Garuda Linux
- ✅ Manjaro
- ✅ EndeavourOS
- ✅ Ubuntu 22.04+
- ✅ Pop!_OS
- ✅ Linux Mint

---

## Installation Methods

We provide **three installation methods**:

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| **Docker** 🐳 | Easy updates, isolated, reproducible | Requires Docker knowledge | Most users |
| **NPM** 📦 | Lightweight, direct control | Requires Node.js management | Developers |
| **Desktop App** 🖥️ | Simplest, GUI-based | Limited customization | Beginners |

**We recommend Docker for most users.**

---

## 🏔️ Arch-based Installation

> **For:** Garuda Linux, Manjaro, EndeavourOS, Arch Linux, ArcoLinux

### Method 1: Docker Installation (Recommended)

#### Step 1: Update System

```bash
# Update package database and system
sudo pacman -Syu
```

**Why?** Ensures you have the latest packages and avoids conflicts.

#### Step 2: Install Docker

```bash
# Install Docker and Docker Compose
sudo pacman -S docker docker-compose

# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker
```

**Explanation:**
- `docker`: Container runtime
- `docker-compose`: Tool for defining multi-container applications
- `systemctl start`: Starts the service now
- `systemctl enable`: Makes it start automatically on boot

#### Step 3: Add User to Docker Group

```bash
# Add your user to docker group (avoids needing sudo)
sudo usermod -aG docker $USER

# Apply group changes (choose one):
# Option A: Log out and log back in
# Option B: Run this command
newgrp docker
```

**Why?** Allows you to run Docker commands without `sudo`.

#### Step 4: Verify Docker Installation

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker-compose --version

# Test Docker (should show "Hello from Docker!")
docker run hello-world
```

#### Step 5: Create n8n Directory

```bash
# Create directory for n8n configuration and data
mkdir -p ~/.n8n

# Navigate to the directory
cd ~/.n8n
```

**Explanation:** This directory will store:
- Your workflows
- Credentials
- Execution history
- Configuration files

#### Step 6: Create Docker Compose Configuration

```bash
# Create docker-compose.yml file
nvim docker-compose.yml
```

Or if you prefer nano:
```bash
nano docker-compose.yml
```

**Copy and paste this configuration:**

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      # Authentication settings
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=changeme123  # CHANGE THIS!
      
      # Server settings
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      
      # Timezone (change to your timezone)
      - GENERIC_TIMEZONE=Asia/Kolkata
      
      # Performance settings
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168  # 7 days
      
    volumes:
      - ~/.n8n:/home/node/.n8n
    
    # Optional: Resource limits
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
```

** IMPORTANT:** Change `changeme123` to a strong password!

**Configuration Explained:**
- `ports`: Maps container port 5678 to your host port 5678
- `N8N_BASIC_AUTH_*`: Login credentials for web interface
- `WEBHOOK_URL`: URL for webhook triggers
- `GENERIC_TIMEZONE`: Your local timezone
- `volumes`: Persists data on your host machine
- `restart: unless-stopped`: Auto-restarts container if it crashes

#### Step 7: Start n8n

```bash
# Start n8n container in detached mode
docker-compose up -d

# Check if container is running
docker ps

# View logs (Ctrl+C to exit)
docker-compose logs -f
```

**Expected output:**
```
✔ Container n8n  Started
```

#### Step 8: Access n8n

Open your browser and navigate to:
```
http://localhost:5678
```

**Login credentials:**
- Username: `admin`
- Password: `changeme123` (or your custom password)

---

### Method 2: NPM Installation

#### Step 1: Install Node.js

```bash
# Install Node.js and npm
sudo pacman -S nodejs npm

# Verify installation
node --version  # Should be v18+
npm --version
```

#### Step 2: Install n8n Globally

```bash
# Install n8n via npm
npm install -g n8n

# If you get permission errors:
sudo npm install -g n8n --unsafe-perm
```

**Explanation:**
- `-g`: Installs globally (available system-wide)
- `--unsafe-perm`: Allows installation scripts to run with elevated privileges

#### Step 3: Start n8n

```bash
# Start n8n
n8n start
```

**To run in background:**
```bash
# Start in background
nohup n8n start > n8n.log 2>&1 &

# Check if running
ps aux | grep n8n
```

#### Step 4: Access n8n

Open browser: `http://localhost:5678`

On first run, you'll create an account (stored locally).

---

### Method 3: Desktop App (AppImage)

#### Step 1: Install Dependencies

```bash
# Install FUSE (required for AppImages)
sudo pacman -S fuse2
```

#### Step 2: Download n8n Desktop

```bash
# Create directory for applications
mkdir -p ~/.local/bin

# Download latest version (check GitHub releases for latest version)
cd ~/.local/bin
wget https://github.com/n8n-io/n8n-desktop/releases/download/v1.19.0/n8n-1.19.0.AppImage

# Make executable
chmod +x n8n-1.19.0.AppImage

# Run it
./n8n-1.19.0.AppImage
```

#### Step 3: Create Desktop Entry (Optional)

```bash
# Create desktop entry file
cat > ~/.local/share/applications/n8n.desktop << 'EOF'
[Desktop Entry]
Name=n8n
Comment=Workflow Automation
Exec=/home/YOUR_USERNAME/.local/bin/n8n-1.19.0.AppImage
Icon=n8n
Terminal=false
Type=Application
Categories=Development;Utility;
EOF
```

**Replace `YOUR_USERNAME` with your actual username.**

---

## 🐧 Debian-based Installation

> **For:** Ubuntu, Pop!_OS, Linux Mint, Debian, elementary OS

### Method 1: Docker Installation (Recommended)

#### Step 1: Update System

```bash
# Update package list
sudo apt update

# Upgrade installed packages
sudo apt upgrade -y
```

#### Step 2: Install Docker

```bash
# Install prerequisites
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Or install docker-compose separately if needed
sudo apt install -y docker-compose
```

**Explanation:**
- Prerequisites ensure secure package downloads
- GPG key verifies package authenticity
- Repository setup allows `apt` to find Docker packages

#### Step 3: Configure Docker

```bash
# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Apply group changes (or log out and back in)
newgrp docker
```

#### Step 4: Verify Installation

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker-compose --version

# Test Docker
docker run hello-world
```

#### Step 5: Create n8n Setup

```bash
# Create directory for n8n
mkdir -p ~/.n8n
cd ~/.n8n

# Create docker-compose.yml
nano docker-compose.yml
```

**Paste this configuration:**

```yaml
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
      - N8N_BASIC_AUTH_PASSWORD=changeme123  # CHANGE THIS!
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=America/New_York  # Change to your timezone
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
    volumes:
      - ~/.n8n:/home/node/.n8n
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
```

Save with `Ctrl+X`, then `Y`, then `Enter`.

#### Step 6: Start n8n

```bash
# Start n8n
docker-compose up -d

# Check status
docker ps

# View logs
docker-compose logs -f
```

#### Step 7: Access n8n

Browser: `http://localhost:5678`

---

### Method 2: NPM Installation

#### Step 1: Install Node.js

```bash
# Install Node.js and npm
sudo apt update
sudo apt install -y nodejs npm

# Check versions
node --version
npm --version
```

**For newer Node.js version (recommended):**
```bash
# Install NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell configuration
source ~/.bashrc

# Install latest LTS Node.js
nvm install --lts
nvm use --lts

# Verify
node --version  # Should be v20+
```

#### Step 2: Install n8n

```bash
# Install n8n globally
npm install -g n8n

# If permission errors occur:
sudo npm install -g n8n --unsafe-perm
```

#### Step 3: Start n8n

```bash
# Start n8n
n8n start

# Or run in background:
nohup n8n start > n8n.log 2>&1 &
```

#### Step 4: Access n8n

Browser: `http://localhost:5678`

---

### Method 3: Desktop App (AppImage)

#### Step 1: Install Dependencies

```bash
# Install FUSE
sudo apt install -y fuse libfuse2
```

#### Step 2: Download and Run

```bash
# Create directory
mkdir -p ~/.local/bin
cd ~/.local/bin

# Download (check for latest version)
wget https://github.com/n8n-io/n8n-desktop/releases/download/v1.19.0/n8n-1.19.0.AppImage

# Make executable
chmod +x n8n-1.19.0.AppImage

# Run
./n8n-1.19.0.AppImage
```

---

## ⚙️ Post-Installation Setup

### Enable Auto-Start on Boot (Docker)

#### For Arch-based Systems:

```bash
# Create systemd service
sudo tee /etc/systemd/system/n8n-docker.service > /dev/null << 'EOF'
[Unit]
Description=n8n Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/YOUR_USERNAME/.n8n
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=YOUR_USERNAME

[Install]
WantedBy=multi-user.target
EOF

# Replace YOUR_USERNAME with your actual username
# Then enable the service
sudo systemctl daemon-reload
sudo systemctl enable n8n-docker.service
sudo systemctl start n8n-docker.service
```

#### For Debian-based Systems:

Same as above, just ensure the path to docker-compose is correct:

```bash
# Find docker-compose location
which docker-compose
# Use this path in the service file
```

---

### Configure Firewall (If Enabled)

#### UFW (Ubuntu/Debian):

```bash
# Allow n8n port
sudo ufw allow 5678/tcp

# Check status
sudo ufw status
```

#### Firewalld (Some Arch systems):

```bash
# Allow port
sudo firewall-cmd --permanent --add-port=5678/tcp
sudo firewall-cmd --reload
```

---

### Access from Other Devices (Optional)

To access n8n from your phone or other computers on the same network:

#### Step 1: Find Your Local IP

```bash
# Get local IP address
ip addr show | grep "inet 192"
# Example output: 192.168.1.100
```

#### Step 2: Update Docker Configuration

Edit `~/.n8n/docker-compose.yml`:

```yaml
environment:
  - N8N_HOST=0.0.0.0  # Listen on all interfaces
  - WEBHOOK_URL=http://192.168.1.100:5678/  # Your local IP
```

#### Step 3: Restart n8n

```bash
cd ~/.n8n
docker-compose down
docker-compose up -d
```

#### Step 4: Access from Other Devices

From any device on the same network:
```
http://192.168.1.100:5678
```

---

## 📚 Usage Guide

### Creating Your First Workflow

1. **Access n8n**: Open `http://localhost:5678`
2. **Login** with your credentials
3. **Click "Add Workflow"** button (top right)
4. **Add trigger node**: Click the "+" button
   - Choose "Schedule Trigger" for time-based automation
   - Or "Webhook" for API triggers
5. **Add action node**: Click "+" after trigger
   - Choose from 300+ integrations
   - Example: "HTTP Request", "Google Sheets", "Discord"
6. **Configure nodes**: Click each node to set parameters
7. **Test workflow**: Click "Execute Workflow" button
8. **Activate**: Toggle switch in top-right corner

### Example Workflow: Daily Weather Report

```
Schedule Trigger (every day 8 AM)
  ↓
HTTP Request (fetch weather API)
  ↓
Set (format data)
  ↓
Discord/Email (send notification)
```

---

## 🛠️ Common Commands

### Docker Commands

```bash
# Start n8n
cd ~/.n8n && docker-compose up -d

# Stop n8n
docker-compose down

# Restart n8n
docker-compose restart

# View logs (live)
docker-compose logs -f

# View last 100 lines of logs
docker-compose logs --tail=100

# Update n8n to latest version
docker-compose pull
docker-compose up -d

# Check container status
docker ps

# Access n8n container shell
docker exec -it n8n /bin/sh
```

### NPM Commands

```bash
# Start n8n
n8n start

# Start with custom port
n8n start --port 5679

# Update n8n
npm update -g n8n

# Check version
n8n --version

# Uninstall n8n
npm uninstall -g n8n
```

---

## 🔧 Troubleshooting

### Issue: Port 5678 Already in Use

**Solution:**

```bash
# Find what's using the port
sudo lsof -i :5678

# Kill the process (replace PID)
kill -9 PID

# Or use a different port in docker-compose.yml:
ports:
  - "5679:5678"  # Access via localhost:5679
```

### Issue: Docker Permission Denied

**Solution:**

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker

# Verify
groups  # Should show 'docker' in the list
```

### Issue: Cannot Access n8n from Browser

**Solution:**

```bash
# Check if n8n is running
docker ps  # For Docker
ps aux | grep n8n  # For NPM

# Check firewall
sudo ufw status
sudo ufw allow 5678

# Try accessing with:
http://127.0.0.1:5678
# Or
http://localhost:5678

# Check Docker logs
docker-compose logs n8n
```

### Issue: n8n Command Not Found (NPM)

**Solution:**

```bash
# Check if installed
npm list -g n8n

# Reinstall
sudo npm install -g n8n --unsafe-perm

# Add npm global to PATH
echo 'export PATH="$PATH:$(npm config get prefix)/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: High CPU/Memory Usage

**Solution:**

Edit `docker-compose.yml` to limit resources:

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M
```

Then restart:
```bash
docker-compose down && docker-compose up -d
```

### Issue: Workflows Not Executing

**Solution:**

```bash
# Check n8n logs
docker-compose logs -f n8n

# Ensure workflow is activated (toggle in UI)

# Check webhook URLs are correct

# Verify timezone settings in docker-compose.yml
```

---

## 💾 Backup and Restore

### Backup n8n Data

```bash
# For Docker installation
cd ~
tar -czf n8n-backup-$(date +%Y%m%d).tar.gz .n8n/

# Move to safe location
mv n8n-backup-*.tar.gz /path/to/backup/location/
```

### Restore from Backup

```bash
# Stop n8n
cd ~/.n8n && docker-compose down

# Restore backup
cd ~
tar -xzf /path/to/backup/n8n-backup-YYYYMMDD.tar.gz

# Start n8n
cd ~/.n8n && docker-compose up -d
```

---

## 🔄 Updating n8n

### Docker Method

```bash
cd ~/.n8n

# Pull latest image
docker-compose pull

# Restart with new image
docker-compose up -d

# Verify version
docker exec n8n n8n --version
```

### NPM Method

```bash
# Update to latest version
npm update -g n8n

# Or specific version
npm install -g n8n@1.19.0

# Verify
n8n --version
```

---

## 🎯 Performance Optimization

### Optimize Docker Performance

Add to `docker-compose.yml`:

```yaml
environment:
  # Limit execution history
  - EXECUTIONS_DATA_PRUNE=true
  - EXECUTIONS_DATA_MAX_AGE=168  # 7 days
  
  # Reduce log verbosity
  - N8N_LOG_LEVEL=warn
  
  # Disable metrics if not needed
  - N8N_METRICS=false

# Resource limits
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 1G
    reservations:
      memory: 512M
```

---

## 📖 Useful Resources

- **Official Documentation**: https://docs.n8n.io
- **n8n Community Forum**: https://community.n8n.io
- **Workflow Templates**: https://n8n.io/workflows
- **GitHub Repository**: https://github.com/n8n-io/n8n
- **Discord Community**: https://discord.gg/n8n

---

## 🤝 Contributing

Found an issue or have a suggestion? Contributions are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

---

## 📝 License

This guide is released under the MIT License. n8n itself is licensed under the [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md).

---

##  Show Your Support

If this guide helped you, please consider:
- Starring this repository
- Reporting issues
- Contributing improvements
-  Sharing with others

---

##  Acknowledgments

- n8n team for creating this amazing tool
- The open-source community
- All contributors to this guide

---

**Made with ❤️ for the Linux community**

*Last updated: January 2026*
