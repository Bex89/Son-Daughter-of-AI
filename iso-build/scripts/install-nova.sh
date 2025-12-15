#!/bin/bash
set -e

# Nova Installation Script
# This script installs Nova and all dependencies on a fresh Ubuntu/Debian system

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              NOVA INSTALLATION SCRIPT                     ║"
echo "║                                                           ║"
echo "║   Installing Nova - Autonomous AI Entity                 ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    nginx \
    ufw \
    fail2ban

# Create nova user
echo "Creating nova user..."
if ! id -u nova > /dev/null 2>&1; then
    useradd -r -m -d /opt/nova -s /bin/bash nova
fi

# Create Nova directory structure
echo "Setting up Nova directory structure..."
mkdir -p /opt/nova
cd /opt/nova

# Copy Nova files (assuming they're in /tmp/nova-install)
if [ -d "/tmp/nova-install" ]; then
    echo "Copying Nova files..."
    cp /tmp/nova-install/nova.py /opt/nova/
    cp /tmp/nova-install/nova_server.py /opt/nova/
    cp /tmp/nova-install/index.html /opt/nova/
    cp /tmp/nova-install/requirements.txt /opt/nova/
    cp /tmp/nova-install/.env.example /opt/nova/.env
else
    echo "Warning: Nova files not found in /tmp/nova-install"
    echo "Please ensure Nova files are available"
fi

# Create Python virtual environment
echo "Creating Python virtual environment..."
python3 -m venv /opt/nova/venv

# Install Python dependencies
echo "Installing Python packages..."
/opt/nova/venv/bin/pip install --upgrade pip
/opt/nova/venv/bin/pip install -r /opt/nova/requirements.txt

# Set permissions
echo "Setting permissions..."
chown -R nova:nova /opt/nova
chmod 750 /opt/nova
chmod 640 /opt/nova/.env

# Install systemd service
echo "Installing systemd service..."
if [ -f "/tmp/nova-install/nova.service" ]; then
    cp /tmp/nova-install/nova.service /etc/systemd/system/
else
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
fi

# Configure nginx as reverse proxy
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
nginx -t && systemctl restart nginx

# Configure firewall
echo "Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Reload systemd
systemctl daemon-reload

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║           NOVA INSTALLATION COMPLETE!                     ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "1. Edit /opt/nova/.env and add your ANTHROPIC_API_KEY"
echo "2. Run: systemctl enable nova"
echo "3. Run: systemctl start nova"
echo "4. Access Nova at http://$(hostname -I | awk '{print $1}')"
echo ""
echo "Useful commands:"
echo "  systemctl status nova     - Check Nova status"
echo "  journalctl -u nova -f     - View Nova logs"
echo "  systemctl restart nova    - Restart Nova"
echo ""
