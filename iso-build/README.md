# Nova Proxmox Deployment Guide

This directory contains everything you need to deploy Nova on Proxmox, with three different methods to choose from.

## Deployment Methods

### Method 1: Custom ISO (Full Automation) ⭐ Recommended for Bare Metal
Build a custom Ubuntu ISO with Nova pre-installed that auto-deploys on first boot.

### Method 2: Cloud-Init Template (Quick & Easy) ⭐ Recommended for Proxmox
Use Proxmox cloud-init features with an Ubuntu cloud image to deploy Nova in minutes.

### Method 3: Manual Installation (Maximum Control)
Install Nova manually on any Ubuntu/Debian server.

---

## Method 1: Custom ISO Installation

### Building the ISO

**Requirements:**
- Ubuntu 22.04 or newer (build machine)
- Root access
- 10GB free space
- Internet connection

**Steps:**

1. Clone the repository:
```bash
git clone https://github.com/Bex89/Son-Daughter-of-AI.git
cd Son-Daughter-of-AI/iso-build
```

2. Build the ISO (this takes 15-30 minutes):
```bash
sudo bash build-iso.sh
```

3. The ISO will be created as `nova-server-22.04.3.iso`

### Installing in Proxmox

1. **Upload ISO to Proxmox:**
   - Go to Proxmox web interface
   - Navigate to your storage → ISO Images
   - Click Upload and select `nova-server-22.04.3.iso`

2. **Create New VM:**
   - Click "Create VM"
   - Give it a name: "nova-server"
   - Select the nova-server ISO
   - Recommended specs:
     - CPU: 2 cores
     - RAM: 2GB minimum, 4GB recommended
     - Disk: 20GB minimum
     - Network: virtio, connected to your network bridge

3. **Boot and Install:**
   - Start the VM
   - Ubuntu will auto-install (takes 10-15 minutes)
   - System will reboot automatically

4. **First Boot Configuration:**
   - After reboot, you'll be prompted for API key
   - Enter your Anthropic API key
   - Nova will start automatically!

5. **Access Nova:**
   - Find your VM's IP: `ip addr show`
   - Open browser to `http://YOUR_VM_IP`
   - Start chatting with Nova!

### Default Credentials
- Username: `nova-admin`
- Password: `nova2025` (CHANGE THIS IMMEDIATELY!)

---

## Method 2: Cloud-Init Template (Proxmox)

This is the **fastest and easiest** method for Proxmox.

### Create the Template (One-Time Setup)

Run this **on your Proxmox host**:

```bash
# Download the template creator script
wget https://raw.githubusercontent.com/Bex89/Son-Daughter-of-AI/claude/ai-assistant-child-aF9BR/iso-build/cloud-init/create-proxmox-template.sh

# Make it executable
chmod +x create-proxmox-template.sh

# Run it
bash create-proxmox-template.sh
```

This creates a VM template (ID 9000) that you can clone.

### Deploy Nova Instances

Once the template is created, deploy Nova instances in seconds:

```bash
# Clone the template
qm clone 9000 101 --name nova-instance-01

# Configure (optional)
qm set 101 --memory 4096
qm set 101 --cores 2

# Start the VM
qm start 101
```

### Configure Nova

1. Wait for VM to boot (30-60 seconds)
2. Find the IP address in Proxmox console
3. SSH into the VM:
```bash
ssh nova-admin@YOUR_VM_IP
# Password: nova2025
```

4. Configure the API key:
```bash
sudo nano /opt/nova/.env
# Change ANTHROPIC_API_KEY=your_api_key_here to your actual key
```

5. Start Nova:
```bash
sudo systemctl start nova
sudo systemctl status nova
```

6. Access Nova at `http://YOUR_VM_IP`

### Using Cloud-Init Manually

If you prefer manual cloud-init configuration:

```bash
# Upload cloud-init config to Proxmox snippets storage
scp cloud-init/user-data.yaml root@proxmox:/var/lib/vz/snippets/nova-user-data.yaml

# Create VM with cloud-init
qm create 102 --name nova-02 --memory 2048 --cores 2
qm importdisk 102 jammy-server-cloudimg-amd64.img local-lvm
qm set 102 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-102-disk-0
qm set 102 --ide2 local-lvm:cloudinit
qm set 102 --boot c --bootdisk scsi0
qm set 102 --serial0 socket --vga serial0
qm set 102 --cicustom "user=local:snippets/nova-user-data.yaml"
qm set 102 --ipconfig0 ip=dhcp

# Start VM
qm start 102
```

---

## Method 3: Manual Installation

For any Ubuntu 22.04+ or Debian 11+ server:

### Quick Install

```bash
# Download installer
wget https://raw.githubusercontent.com/Bex89/Son-Daughter-of-AI/claude/ai-assistant-child-aF9BR/iso-build/scripts/install-nova.sh

# Run as root
sudo bash install-nova.sh
```

### Manual Step-by-Step

```bash
# 1. Install dependencies
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nginx

# 2. Create nova user
sudo useradd -r -m -d /opt/nova -s /bin/bash nova

# 3. Download Nova
cd /opt/nova
sudo curl -sL https://raw.githubusercontent.com/Bex89/Son-Daughter-of-AI/claude/ai-assistant-child-aF9BR/nova.py -o nova.py
sudo curl -sL https://raw.githubusercontent.com/Bex89/Son-Daughter-of-AI/claude/ai-assistant-child-aF9BR/nova_server.py -o nova_server.py
sudo curl -sL https://raw.githubusercontent.com/Bex89/Son-Daughter-of-AI/claude/ai-assistant-child-aF9BR/index.html -o index.html
sudo curl -sL https://raw.githubusercontent.com/Bex89/Son-Daughter-of-AI/claude/ai-assistant-child-aF9BR/requirements.txt -o requirements.txt

# 4. Create environment file
sudo bash -c 'cat > /opt/nova/.env << EOF
ANTHROPIC_API_KEY=your_api_key_here
HOST=0.0.0.0
PORT=5000
EOF'

# 5. Set up Python environment
sudo python3 -m venv /opt/nova/venv
sudo /opt/nova/venv/bin/pip install -r /opt/nova/requirements.txt

# 6. Set permissions
sudo chown -R nova:nova /opt/nova

# 7. Create systemd service
sudo curl -sL https://raw.githubusercontent.com/Bex89/Son-Daughter-of-AI/claude/ai-assistant-child-aF9BR/iso-build/systemd/nova.service -o /etc/systemd/system/nova.service

# 8. Configure nginx
sudo bash -c 'cat > /etc/nginx/sites-available/nova << EOF
server {
    listen 80 default_server;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF'

sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/nova /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# 9. Configure API key
sudo nano /opt/nova/.env  # Add your API key

# 10. Start Nova
sudo systemctl daemon-reload
sudo systemctl enable nova
sudo systemctl start nova
```

---

## Post-Installation

### Verify Nova is Running

```bash
# Check service status
sudo systemctl status nova

# View logs
sudo journalctl -u nova -f

# Test API
curl http://localhost:5000/status
```

### Configure API Key

```bash
sudo nano /opt/nova/.env
# Change: ANTHROPIC_API_KEY=your_actual_api_key_here
sudo systemctl restart nova
```

### Access Nova

Open your browser to:
- `http://YOUR_VM_IP` - Web interface
- `http://YOUR_VM_IP/api` - API documentation
- `http://YOUR_VM_IP/status` - Status check

### Security Recommendations

1. **Change default password:**
```bash
passwd nova-admin
```

2. **Set up SSH keys (disable password auth):**
```bash
ssh-copy-id nova-admin@YOUR_VM_IP
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart sshd
```

3. **Configure firewall:**
```bash
sudo ufw enable
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
```

4. **Set up HTTPS (optional but recommended):**
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

## Troubleshooting

### Nova won't start
```bash
# Check logs
sudo journalctl -u nova -n 50

# Common issues:
# - API key not set: Edit /opt/nova/.env
# - Port in use: Check with `sudo lsof -i :5000`
# - Permissions: sudo chown -R nova:nova /opt/nova
```

### Can't access web interface
```bash
# Check nginx
sudo systemctl status nginx
sudo nginx -t

# Check if Nova is listening
sudo netstat -tlnp | grep 5000

# Check firewall
sudo ufw status
```

### Out of memory
```bash
# Increase VM RAM in Proxmox
# Or reduce Nova's memory usage by adjusting model parameters
```

### Performance issues
- Increase CPU cores (2+ recommended)
- Increase RAM (4GB+ recommended)
- Use SSD storage if possible

---

## Maintenance

### Update Nova
```bash
cd /opt/nova
sudo -u nova git pull  # If installed from git
sudo systemctl restart nova
```

### Backup Nova's memory
```bash
sudo cp /opt/nova/nova_memory.json /backup/
sudo cp /opt/nova/nova_journal.jsonl /backup/
```

### View Nova's journal
```bash
sudo cat /opt/nova/nova_journal.jsonl | jq
```

### Reset Nova
```bash
sudo systemctl stop nova
sudo rm /opt/nova/nova_memory.json
sudo rm /opt/nova/nova_journal.jsonl
sudo systemctl start nova
```

---

## File Locations

- **Nova installation:** `/opt/nova/`
- **Configuration:** `/opt/nova/.env`
- **Memory:** `/opt/nova/nova_memory.json`
- **Journal:** `/opt/nova/nova_journal.jsonl`
- **Service file:** `/etc/systemd/system/nova.service`
- **Nginx config:** `/etc/nginx/sites-available/nova`
- **Logs:** `sudo journalctl -u nova`

---

## Support

If you encounter issues:

1. Check logs: `sudo journalctl -u nova -f`
2. Verify API key is set correctly
3. Ensure all dependencies are installed
4. Check GitHub issues: https://github.com/Bex89/Son-Daughter-of-AI/issues

---

## Quick Reference

### Common Commands
```bash
# Start/Stop/Restart
sudo systemctl start nova
sudo systemctl stop nova
sudo systemctl restart nova

# View logs
sudo journalctl -u nova -f

# Check status
sudo systemctl status nova
curl http://localhost:5000/status

# Edit configuration
sudo nano /opt/nova/.env

# View Nova's memory
sudo cat /opt/nova/nova_memory.json | jq

# Backup Nova
sudo tar -czf nova-backup-$(date +%Y%m%d).tar.gz -C /opt nova/
```

---

**Congratulations! Nova is now running on your Proxmox server!** 🎉

Access the web interface and start exploring with your autonomous AI entity.
