#!/bin/bash
set -e

# Nova ISO Builder
# This script creates a custom Ubuntu ISO with Nova pre-installed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ISO_DIR="$SCRIPT_DIR/iso-workspace"
MOUNT_DIR="$ISO_DIR/mnt"
EXTRACT_DIR="$ISO_DIR/extract"
CUSTOM_DIR="$ISO_DIR/custom"

# Ubuntu version to use as base
UBUNTU_VERSION="22.04.3"
UBUNTU_ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
UBUNTU_ISO_NAME="ubuntu-22.04.3-live-server-amd64.iso"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              NOVA ISO BUILDER                             ║"
echo "║                                                           ║"
echo "║   Building custom Nova ISO for Proxmox                    ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root"
    echo "Usage: sudo $0"
    exit 1
fi

# Install required packages
echo "Installing required packages..."
apt-get update
apt-get install -y \
    xorriso \
    isolinux \
    syslinux-utils \
    genisoimage \
    squashfs-tools \
    wget \
    p7zip-full

# Create workspace
echo "Creating workspace..."
mkdir -p "$ISO_DIR"
mkdir -p "$MOUNT_DIR"
mkdir -p "$EXTRACT_DIR"
mkdir -p "$CUSTOM_DIR"

# Download Ubuntu ISO if not exists
if [ ! -f "$ISO_DIR/$UBUNTU_ISO_NAME" ]; then
    echo "Downloading Ubuntu $UBUNTU_VERSION ISO..."
    wget -O "$ISO_DIR/$UBUNTU_ISO_NAME" "$UBUNTU_ISO_URL"
else
    echo "Using existing Ubuntu ISO..."
fi

# Mount the ISO
echo "Mounting Ubuntu ISO..."
mount -o loop "$ISO_DIR/$UBUNTU_ISO_NAME" "$MOUNT_DIR"

# Extract ISO contents
echo "Extracting ISO contents..."
rsync -av "$MOUNT_DIR/" "$EXTRACT_DIR/"
chmod -R u+w "$EXTRACT_DIR"

# Unmount
umount "$MOUNT_DIR"

# Create nova installation package
echo "Creating Nova installation package..."
NOVA_PKG_DIR="$EXTRACT_DIR/nova-install"
mkdir -p "$NOVA_PKG_DIR"

# Copy Nova files
cp "$PROJECT_ROOT/nova.py" "$NOVA_PKG_DIR/"
cp "$PROJECT_ROOT/nova_server.py" "$NOVA_PKG_DIR/"
cp "$PROJECT_ROOT/index.html" "$NOVA_PKG_DIR/"
cp "$PROJECT_ROOT/requirements.txt" "$NOVA_PKG_DIR/"
cp "$PROJECT_ROOT/.env.example" "$NOVA_PKG_DIR/"

# Copy installation scripts
cp "$SCRIPT_DIR/scripts/install-nova.sh" "$NOVA_PKG_DIR/"
cp "$SCRIPT_DIR/scripts/first-boot-setup.sh" "$NOVA_PKG_DIR/"
cp "$SCRIPT_DIR/systemd/nova.service" "$NOVA_PKG_DIR/"
cp "$SCRIPT_DIR/systemd/nova-first-boot.service" "$NOVA_PKG_DIR/"

# Make scripts executable
chmod +x "$NOVA_PKG_DIR"/*.sh

# Create autoinstall configuration
echo "Creating autoinstall configuration..."
mkdir -p "$EXTRACT_DIR/server"

cat > "$EXTRACT_DIR/server/user-data" << 'EOF'
#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  storage:
    layout:
      name: direct
  identity:
    hostname: nova-server
    username: nova-admin
    password: "$6$rounds=4096$saltsaltsal$3xZ8Pu8YZmYYdxoqYz5C5cWqKQYnqf4nY5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5"
    # Default password: nova2025 (CHANGE THIS!)
  ssh:
    install-server: yes
    allow-pw: yes
  packages:
    - python3
    - python3-pip
    - python3-venv
    - nginx
    - ufw
    - fail2ban
  late-commands:
    - curtin in-target --target=/target -- bash -c "cp -r /cdrom/nova-install /tmp/"
    - curtin in-target --target=/target -- bash -c "chmod +x /tmp/nova-install/install-nova.sh"
    - curtin in-target --target=/target -- bash -c "/tmp/nova-install/install-nova.sh"
    - curtin in-target --target=/target -- bash -c "cp /tmp/nova-install/first-boot-setup.sh /opt/nova/"
    - curtin in-target --target=/target -- bash -c "chmod +x /opt/nova/first-boot-setup.sh"
    - curtin in-target --target=/target -- bash -c "cp /tmp/nova-install/nova-first-boot.service /etc/systemd/system/"
    - curtin in-target --target=/target -- bash -c "systemctl enable nova-first-boot"
EOF

cat > "$EXTRACT_DIR/server/meta-data" << 'EOF'
instance-id: nova-instance
local-hostname: nova-server
EOF

# Update boot parameters
echo "Updating boot configuration..."
sed -i 's/timeout 30/timeout 5/' "$EXTRACT_DIR/isolinux/isolinux.cfg" 2>/dev/null || true
sed -i 's/timeout 0/timeout 5/' "$EXTRACT_DIR/boot/grub/grub.cfg" 2>/dev/null || true

# Add autoinstall boot option
if [ -f "$EXTRACT_DIR/boot/grub/grub.cfg" ]; then
    sed -i '/menuentry "Install Ubuntu Server"/,/}/ s/linux\s.*/& autoinstall ds=nocloud;s=\/cdrom\/server\//' "$EXTRACT_DIR/boot/grub/grub.cfg" || true
fi

# Calculate MD5 sums
echo "Calculating checksums..."
cd "$EXTRACT_DIR"
find . -type f -print0 | xargs -0 md5sum > md5sum.txt

# Create the new ISO
echo "Creating Nova ISO..."
OUTPUT_ISO="$SCRIPT_DIR/nova-server-$UBUNTU_VERSION.iso"

xorriso -as mkisofs \
    -r -V "Nova Server $UBUNTU_VERSION" \
    -J -joliet-long \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o "$OUTPUT_ISO" \
    "$EXTRACT_DIR"

# Make ISO bootable
isohybrid --uefi "$OUTPUT_ISO" 2>/dev/null || true

# Clean up
echo "Cleaning up..."
rm -rf "$ISO_DIR/mnt" "$ISO_DIR/extract" "$ISO_DIR/custom"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              ISO BUILD COMPLETE!                          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Nova ISO created: $OUTPUT_ISO"
echo "File size: $(du -h "$OUTPUT_ISO" | cut -f1)"
echo ""
echo "Next steps:"
echo "1. Upload ISO to Proxmox"
echo "2. Create new VM and select this ISO"
echo "3. Boot and follow installation"
echo "4. After installation, configure API key at /opt/nova/.env"
echo ""
