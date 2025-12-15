# Nova Deployment Guide

Quick guide to deploying Nova on your infrastructure.

## Choose Your Deployment Method

### 🚀 For Proxmox Users (Recommended)

**Option A: Cloud-Init Template** (Fastest - 5 minutes)
```bash
cd iso-build/cloud-init
bash create-proxmox-template.sh
# Then clone the template to create instances
```

**Option B: Custom ISO** (Most automated)
```bash
cd iso-build
sudo bash build-iso.sh
# Upload ISO to Proxmox and install like a normal OS
```

### 🐳 For Docker Users

```bash
# Quick start
cp .env.example .env
# Edit .env and add your API key
docker-compose up -d
```

### 💻 For Bare Metal / VPS

```bash
cd iso-build/scripts
sudo bash install-nova.sh
# Edit /opt/nova/.env with your API key
sudo systemctl start nova
```

## Detailed Instructions

See [`iso-build/README.md`](iso-build/README.md) for comprehensive deployment instructions including:
- Custom ISO building
- Proxmox template creation
- Manual installation steps
- Troubleshooting
- Security hardening
- Backup procedures

## Quick Test (Local Development)

```bash
# Install dependencies
pip install -r requirements.txt

# Set API key
export ANTHROPIC_API_KEY=your_key_here

# Run Nova
python nova_server.py

# Access at http://localhost:5000
```

## System Requirements

### Minimum
- 1 CPU core
- 1GB RAM
- 10GB disk space
- Ubuntu 20.04+ or Debian 11+

### Recommended
- 2 CPU cores
- 4GB RAM
- 20GB disk space (SSD)
- Ubuntu 22.04 LTS

## Ports

- **5000**: Nova internal port
- **80**: HTTP (via nginx reverse proxy)
- **443**: HTTPS (if configured)

## Environment Variables

Required:
- `ANTHROPIC_API_KEY`: Your Anthropic API key

Optional:
- `HOST`: Bind address (default: 0.0.0.0)
- `PORT`: Port number (default: 5000)

## Security Checklist

- [ ] Change default passwords
- [ ] Set up SSH keys
- [ ] Configure firewall
- [ ] Set up HTTPS/SSL
- [ ] Regular backups
- [ ] Keep system updated

## Getting Help

1. Check logs: `sudo journalctl -u nova -f`
2. Verify status: `curl http://localhost/status`
3. Read full docs: [`iso-build/README.md`](iso-build/README.md)
4. GitHub issues: https://github.com/Bex89/Son-Daughter-of-AI/issues

---

**Ready to deploy?** Follow the appropriate method above and Nova will be running in minutes!
