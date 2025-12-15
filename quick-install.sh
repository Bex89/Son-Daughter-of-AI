#!/bin/bash
# Nova Quick Installer
# One-command installation of Nova on Ubuntu/Debian
# Usage: curl -sSL https://raw.githubusercontent.com/Bex89/Son-Daughter-of-AI/claude/ai-assistant-child-aF9BR/quick-install.sh | sudo bash

set -e

BRANCH="claude/ai-assistant-child-aF9BR"
BASE_URL="https://raw.githubusercontent.com/Bex89/Son-Daughter-of-AI/$BRANCH"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║           NOVA QUICK INSTALLER                            ║"
echo "║                                                           ║"
echo "║   Installing Nova - Autonomous AI Entity                 ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root"
    echo "Usage: curl -sSL $BASE_URL/quick-install.sh | sudo bash"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "Error: Cannot detect OS"
    exit 1
fi

# Check if OS is supported
if [ "$OS" != "ubuntu" ] && [ "$OS" != "debian" ]; then
    echo "Error: This installer only supports Ubuntu and Debian"
    echo "Detected: $OS $VER"
    exit 1
fi

echo "Detected: $OS $VER"
echo ""

# Update system
echo "Updating system packages..."
apt-get update -qq

# Install dependencies
echo "Installing dependencies..."
apt-get install -y -qq \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    curl \
    wget

# Create nova user
echo "Creating nova user..."
if ! id -u nova > /dev/null 2>&1; then
    useradd -r -m -d /opt/nova -s /bin/bash nova
fi

# Create directory
echo "Setting up Nova directory..."
mkdir -p /opt/nova
cd /opt/nova

# Download Nova files
echo "Downloading Nova components..."
curl -sSL "$BASE_URL/nova.py" -o nova.py
curl -sSL "$BASE_URL/nova_server.py" -o nova_server.py
curl -sSL "$BASE_URL/index.html" -o index.html
curl -sSL "$BASE_URL/requirements.txt" -o requirements.txt

# Create environment file
echo "Creating environment configuration..."
cat > /opt/nova/.env << 'EOF'
ANTHROPIC_API_KEY=your_api_key_here
HOST=0.0.0.0
PORT=5000
EOF

# Create Python virtual environment
echo "Setting up Python environment..."
python3 -m venv /opt/nova/venv
/opt/nova/venv/bin/pip install -q --upgrade pip
/opt/nova/venv/bin/pip install -q -r /opt/nova/requirements.txt

# Set permissions
echo "Setting permissions..."
chown -R nova:nova /opt/nova
chmod 750 /opt/nova
chmod 640 /opt/nova/.env

# Create systemd service
echo "Installing systemd service..."
cat > /etc/systemd/system/nova.service << 'EOF'
[Unit]
Description=Nova - Autonomous AI Entity
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=nova
Group=nova
WorkingDirectory=/opt/nova
Environment="PATH=/opt/nova/venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/opt/nova/.env
ExecStart=/opt/nova/venv/bin/python /opt/nova/nova_server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=nova

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/nova
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

[Install]
WantedBy=multi-user.target
EOF

# Configure nginx
echo "Configuring nginx..."
cat > /etc/nginx/sites-available/nova << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable nginx site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/nova /etc/nginx/sites-enabled/
nginx -t > /dev/null 2>&1 && systemctl restart nginx

# Reload systemd
systemctl daemon-reload
systemctl enable nova

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║        NOVA INSTALLATION COMPLETE!                        ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure your API key:"
echo "   sudo nano /opt/nova/.env"
echo "   (Get your key at: https://console.anthropic.com/)"
echo ""
echo "2. Start Nova:"
echo "   sudo systemctl start nova"
echo ""
echo "3. Check status:"
echo "   sudo systemctl status nova"
echo ""
echo "4. Access Nova:"
echo "   http://$(hostname -I | awk '{print $1}')"
echo ""
echo "Useful commands:"
echo "  sudo journalctl -u nova -f      # View logs"
echo "  sudo systemctl restart nova     # Restart service"
echo "  curl http://localhost/status    # Check API"
echo ""
echo "Full documentation:"
echo "  https://github.com/Bex89/Son-Daughter-of-AI"
echo ""
