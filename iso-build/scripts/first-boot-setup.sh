#!/bin/bash
# Nova First Boot Setup Script
# This script runs on first boot to configure Nova

SETUP_FLAG="/opt/nova/.setup_complete"

# Check if setup already completed
if [ -f "$SETUP_FLAG" ]; then
    exit 0
fi

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              NOVA FIRST BOOT SETUP                        ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Function to get user input
get_api_key() {
    while true; do
        echo "Please enter your Anthropic API key:"
        echo "(Get one at: https://console.anthropic.com/)"
        read -r API_KEY

        if [ -n "$API_KEY" ]; then
            # Update .env file
            sed -i "s/ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=$API_KEY/" /opt/nova/.env
            echo "API key configured!"
            break
        else
            echo "API key cannot be empty. Please try again."
        fi
    done
}

# Check if running interactively
if [ -t 0 ]; then
    # Interactive mode
    get_api_key
else
    # Non-interactive - check if API key is already set
    source /opt/nova/.env
    if [ "$ANTHROPIC_API_KEY" = "your_api_key_here" ] || [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "Warning: API key not configured"
        echo "Please edit /opt/nova/.env and add your ANTHROPIC_API_KEY"
        echo "Then run: systemctl restart nova"
    fi
fi

# Enable and start Nova service
echo "Enabling Nova service..."
systemctl enable nova
systemctl start nova

# Wait a moment for service to start
sleep 3

# Check if service started successfully
if systemctl is-active --quiet nova; then
    echo ""
    echo "✨ Nova is now running!"
    echo ""
    echo "Access Nova at:"
    echo "  http://$(hostname -I | awk '{print $1}')"
    echo ""
else
    echo ""
    echo "⚠️  Nova service failed to start"
    echo "Check logs with: journalctl -u nova -n 50"
    echo ""
fi

# Mark setup as complete
touch "$SETUP_FLAG"

echo "Setup complete!"
