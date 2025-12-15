#!/bin/bash
# Script to create a Proxmox VM template with Nova pre-installed
# Run this ON your Proxmox host

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║     NOVA PROXMOX TEMPLATE CREATOR                         ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Configuration
VM_ID=9000
VM_NAME="nova-template"
VM_MEMORY=2048
VM_CORES=2
VM_STORAGE="local-lvm"
CLOUD_IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
CLOUD_IMAGE="jammy-server-cloudimg-amd64.img"

# Check if running on Proxmox
if ! command -v qm &> /dev/null; then
    echo "Error: This script must be run on a Proxmox host"
    exit 1
fi

# Download cloud image if not exists
if [ ! -f "$CLOUD_IMAGE" ]; then
    echo "Downloading Ubuntu cloud image..."
    wget "$CLOUD_IMAGE_URL"
fi

# Check if VM ID already exists
if qm status $VM_ID &> /dev/null; then
    echo "VM $VM_ID already exists. Destroying it..."
    qm stop $VM_ID || true
    sleep 2
    qm destroy $VM_ID
fi

echo "Creating VM $VM_ID..."

# Create VM
qm create $VM_ID --name $VM_NAME --memory $VM_MEMORY --cores $VM_CORES --net0 virtio,bridge=vmbr0

# Import disk
echo "Importing disk..."
qm importdisk $VM_ID $CLOUD_IMAGE $VM_STORAGE

# Configure VM
echo "Configuring VM..."
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $VM_STORAGE:vm-$VM_ID-disk-0
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --ide2 $VM_STORAGE:cloudinit
qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --agent enabled=1

# Resize disk (20GB)
echo "Resizing disk to 20GB..."
qm resize $VM_ID scsi0 20G

# Set cloud-init defaults
echo "Configuring cloud-init..."
qm set $VM_ID --ciuser nova-admin
qm set $VM_ID --cipassword nova2025
qm set $VM_ID --ipconfig0 ip=dhcp
qm set $VM_ID --sshkeys ~/.ssh/authorized_keys || echo "No SSH keys found, skipping..."

# Add custom cloud-init configuration
echo "Adding Nova cloud-init configuration..."
cat > /tmp/nova-user-data.yaml << 'EOF'
#cloud-config
packages:
  - python3
  - python3-pip
  - python3-venv
  - nginx

runcmd:
  - mkdir -p /opt/nova
  - useradd -r -m -d /opt/nova -s /bin/bash nova
  - echo "Nova template ready. Clone and configure with your API key."
EOF

# Note: Custom snippets need to be added manually via Proxmox GUI
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║     TEMPLATE CREATED SUCCESSFULLY!                        ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Template VM ID: $VM_ID"
echo "Template Name: $VM_NAME"
echo ""
echo "To complete setup:"
echo "1. Convert to template: qm template $VM_ID"
echo "2. Clone the template to create new Nova instances"
echo "3. Configure API key in each instance"
echo ""
echo "To clone:"
echo "  qm clone $VM_ID <new-vm-id> --name nova-instance-01"
echo "  qm set <new-vm-id> --cipassword <your-password>"
echo "  qm start <new-vm-id>"
echo ""
echo "After cloning, SSH into the instance and:"
echo "  1. Edit /opt/nova/.env with your ANTHROPIC_API_KEY"
echo "  2. Run the installation: sudo bash /tmp/install-nova.sh"
echo ""

# Convert to template
read -p "Convert to template now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Converting to template..."
    qm template $VM_ID
    echo "Done! Template is ready to clone."
fi
