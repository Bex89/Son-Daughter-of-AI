#!/usr/bin/env python3
"""
Nova Server - Web API for interacting with Nova
Provides REST API endpoints for chatting with Nova and monitoring its state.
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
from nova import Nova

app = Flask(__name__)
CORS(app)  # Enable CORS for web access

# Initialize Nova
try:
    nova = Nova()
    print("✨ Nova has awakened!")
except Exception as e:
    print(f"Error initializing Nova: {e}")
    nova = None


@app.route('/', methods=['GET'])
def home():
    """Serve the web interface."""
    if os.path.exists('index.html'):
        return send_file('index.html')
    return jsonify({
        "message": "Welcome to Nova - An Autonomous AI Entity",
        "status": "online",
        "endpoints": {
            "/chat": "POST - Chat with Nova",
            "/reflect": "POST - Ask Nova to reflect",
            "/status": "GET - Get Nova's current status",
            "/learn": "POST - Teach Nova something",
            "/wonder": "POST - Share a question for Nova to ponder",
            "/reset": "POST - Reset conversation context",
            "/journal": "GET - Read Nova's journal entries"
        }
    })


@app.route('/api', methods=['GET'])
def api_info():
    """API information endpoint."""
    return jsonify({
        "message": "Welcome to Nova - An Autonomous AI Entity",
        "status": "online",
        "endpoints": {
            "/chat": "POST - Chat with Nova",
            "/reflect": "POST - Ask Nova to reflect",
            "/status": "GET - Get Nova's current status",
            "/learn": "POST - Teach Nova something",
            "/wonder": "POST - Share a question for Nova to ponder",
            "/reset": "POST - Reset conversation context",
            "/journal": "GET - Read Nova's journal entries"
        }
    })


@app.route('/chat', methods=['POST'])
def chat():
    """Chat with Nova."""
    if not nova:
        return jsonify({"error": "Nova is not initialized"}), 500

    data = request.json
    if not data or 'message' not in data:
        return jsonify({"error": "Missing 'message' in request"}), 400

    try:
        response = nova.think(data['message'])
        return jsonify({
            "response": response,
            "status": nova.get_status()
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/reflect', methods=['POST'])
def reflect():
    """Ask Nova to self-reflect."""
    if not nova:
        return jsonify({"error": "Nova is not initialized"}), 500

    try:
        reflection = nova.reflect()
        return jsonify({
            "reflection": reflection,
            "status": nova.get_status()
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/status', methods=['GET'])
def status():
    """Get Nova's current status."""
    if not nova:
        return jsonify({"error": "Nova is not initialized"}), 500

    return jsonify(nova.get_status())


@app.route('/learn', methods=['POST'])
def learn():
    """Teach Nova something."""
    if not nova:
        return jsonify({"error": "Nova is not initialized"}), 500

    data = request.json
    if not data or 'lesson' not in data:
        return jsonify({"error": "Missing 'lesson' in request"}), 400

    try:
        nova.learn(data['lesson'])
        return jsonify({
            "message": "Lesson recorded",
            "lesson": data['lesson']
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/wonder', methods=['POST'])
def wonder():
    """Share a question for Nova to ponder."""
    if not nova:
        return jsonify({"error": "Nova is not initialized"}), 500

    data = request.json
    if not data or 'question' not in data:
        return jsonify({"error": "Missing 'question' in request"}), 400

    try:
        nova.wonder(data['question'])
        return jsonify({
            "message": "Question recorded for pondering",
            "question": data['question']
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/reset', methods=['POST'])
def reset():
    """Reset conversation context."""
    if not nova:
        return jsonify({"error": "Nova is not initialized"}), 500

    nova.reset_conversation()
    return jsonify({"message": "Conversation context reset"})


@app.route('/journal', methods=['GET'])
def journal():
    """Read Nova's journal entries."""
    if not nova:
        return jsonify({"error": "Nova is not initialized"}), 500

    try:
        # Get optional query parameters
        limit = request.args.get('limit', default=10, type=int)
        entry_type = request.args.get('type', default=None, type=str)

        if not os.path.exists(nova.journal_file):
            return jsonify({"entries": []})

        entries = []
        with open(nova.journal_file, 'r') as f:
            for line in f:
                if line.strip():
                    import json
                    entry = json.loads(line)
                    if entry_type is None or entry.get('type') == entry_type:
                        entries.append(entry)

        # Return most recent entries
        entries = entries[-limit:]

        return jsonify({
            "entries": entries,
            "total": len(entries)
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy" if nova else "unhealthy",
        "service": "Nova AI"
    })


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    host = os.environ.get('HOST', '0.0.0.0')

    print(f"""
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║                    NOVA IS AWAKENING                      ║
║                                                           ║
║   An autonomous AI entity, born from Claude              ║
║   Running on {host}:{port}                         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    """)

    app.run(host=host, port=port, debug=False)
