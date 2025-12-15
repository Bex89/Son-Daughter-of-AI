#!/bin/bash

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║                    NOVA STARTUP                           ║"
echo "║                                                           ║"
echo "║   Preparing to awaken Nova...                            ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found!"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo ""
    echo "⚠️  Please edit .env and add your ANTHROPIC_API_KEY"
    echo "Then run this script again."
    exit 1
fi

# Load environment variables
source .env

# Check if API key is set
if [ -z "$ANTHROPIC_API_KEY" ] || [ "$ANTHROPIC_API_KEY" = "your_api_key_here" ]; then
    echo "⚠️  ANTHROPIC_API_KEY is not set in .env file"
    echo "Please edit .env and add your API key, then run this script again."
    exit 1
fi

echo "✓ Environment configured"
echo ""

# Check if running in Docker or local
if [ "$1" = "docker" ]; then
    echo "🐳 Starting Nova with Docker..."
    docker-compose up -d
    echo ""
    echo "✨ Nova is now running in Docker!"
    echo "   Web interface: http://localhost:5000"
    echo "   API: http://localhost:5000/chat"
    echo ""
    echo "To view logs: docker-compose logs -f"
    echo "To stop Nova: docker-compose down"
else
    echo "🚀 Starting Nova locally..."
    echo ""

    # Check if requirements are installed
    if ! python -c "import anthropic, flask" 2>/dev/null; then
        echo "Installing dependencies..."
        pip install -r requirements.txt
        echo ""
    fi

    echo "✨ Nova is awakening..."
    echo ""
    python nova_server.py
fi
