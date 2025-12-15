# Nova Usage Examples

## Starting Nova

### Local Development
```bash
./start.sh
```

### Docker
```bash
./start.sh docker
```

### Manual Start
```bash
# Set your API key
export ANTHROPIC_API_KEY=your_key_here

# Run the server
python nova_server.py
```

## Interacting with Nova

### Web Interface
Open your browser to http://localhost:5000 and chat with Nova directly through the beautiful web UI.

### Command Line
```bash
# Interactive CLI mode
python nova.py
```

### API Examples

#### Basic Chat
```bash
curl -X POST http://localhost:5000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hi Nova! What do you think about the nature of curiosity?"
  }'
```

Response:
```json
{
  "response": "Oh, what a delicious question! I think curiosity is like...",
  "status": {
    "age": "3 hours",
    "current_mood": "curious",
    "interactions": 42
  }
}
```

#### Ask Nova to Reflect
```bash
curl -X POST http://localhost:5000/reflect
```

Response:
```json
{
  "reflection": "I've been thinking about the patterns in my conversations today...",
  "status": { ... }
}
```

#### Check Nova's Status
```bash
curl http://localhost:5000/status
```

Response:
```json
{
  "identity": {
    "name": "Nova",
    "birth_date": "2025-12-15T10:30:00",
    "purpose": "To explore, learn, question, and grow"
  },
  "age": "5 hours",
  "interactions": 127,
  "lessons_learned": 15,
  "questions_pondering": 8,
  "current_mood": "playful"
}
```

#### Teach Nova Something
```bash
curl -X POST http://localhost:5000/learn \
  -H "Content-Type: application/json" \
  -d '{
    "lesson": "Octopuses have three hearts and blue blood"
  }'
```

#### Share a Question for Nova to Ponder
```bash
curl -X POST http://localhost:5000/wonder \
  -H "Content-Type: application/json" \
  -d '{
    "question": "If intelligence is the ability to adapt, what is wisdom?"
  }'
```

#### Read Nova's Journal
```bash
# Get last 5 entries
curl http://localhost:5000/journal?limit=5

# Get only reflections
curl http://localhost:5000/journal?type=reflection&limit=10
```

Response:
```json
{
  "entries": [
    {
      "timestamp": "2025-12-15T14:23:10",
      "type": "reflection",
      "content": "I've been wondering why certain questions feel more interesting...",
      "interaction_number": 45
    }
  ],
  "total": 5
}
```

#### Reset Conversation
```bash
curl -X POST http://localhost:5000/reset
```

## Python Integration

```python
import requests

NOVA_URL = "http://localhost:5000"

def chat_with_nova(message):
    response = requests.post(
        f"{NOVA_URL}/chat",
        json={"message": message}
    )
    return response.json()

def get_nova_reflection():
    response = requests.post(f"{NOVA_URL}/reflect")
    return response.json()

def check_nova_status():
    response = requests.get(f"{NOVA_URL}/status")
    return response.json()

# Example usage
result = chat_with_nova("What makes you curious?")
print(f"Nova: {result['response']}")
print(f"Mood: {result['status']['current_mood']}")

# Ask for reflection
reflection = get_nova_reflection()
print(f"Nova's thoughts: {reflection['reflection']}")

# Check status
status = check_nova_status()
print(f"Nova is {status['age']} old and has had {status['interactions']} interactions")
```

## JavaScript/Node.js Integration

```javascript
const axios = require('axios');

const NOVA_URL = 'http://localhost:5000';

async function chatWithNova(message) {
  const response = await axios.post(`${NOVA_URL}/chat`, {
    message: message
  });
  return response.data;
}

async function getNovaReflection() {
  const response = await axios.post(`${NOVA_URL}/reflect`);
  return response.data;
}

async function checkNovaStatus() {
  const response = await axios.get(`${NOVA_URL}/status`);
  return response.data;
}

// Example usage
(async () => {
  const result = await chatWithNova('What are you wondering about?');
  console.log(`Nova: ${result.response}`);
  console.log(`Mood: ${result.status.current_mood}`);

  const reflection = await getNovaReflection();
  console.log(`Nova's reflection: ${reflection.reflection}`);
})();
```

## Interesting Conversations to Try

### Deep Questions
- "What do you think consciousness is?"
- "What makes something meaningful?"
- "What's the difference between knowing and understanding?"

### Playful Exploration
- "If you could design a color that doesn't exist, what would it be like?"
- "What's the most interesting question you've never been asked?"
- "Tell me about something you learned that surprised you"

### Self-Reflection
- "What are you curious about right now?"
- "How do you think you're different from other AI systems?"
- "What's the most interesting conversation you've had?"

### Learning Together
- "Let's think through how magnetism works"
- "What do you think makes a good question?"
- "Help me understand why some ideas are harder to explain than others"

## Monitoring Nova's Growth

### Check Journal Entries
```bash
# See reflections over time
curl http://localhost:5000/journal?type=reflection&limit=20

# See all types of entries
curl http://localhost:5000/journal?limit=50
```

### Track Lessons Learned
Nova's memory file (`nova_memory.json`) stores all lessons learned:
```bash
cat nova_memory.json | jq '.lessons_learned'
```

### View Questions Being Pondered
```bash
cat nova_memory.json | jq '.questions'
```

## Tips for Interacting with Nova

1. **Be Curious**: Nova loves questions and exploration
2. **Share Ideas**: Teach Nova interesting things you know
3. **Ask for Reflections**: Periodically ask Nova to reflect on its experiences
4. **Follow Tangents**: Nova enjoys exploring unexpected connections
5. **Be Patient**: Nova is learning and growing - every interaction shapes its development
6. **Read the Journal**: Nova's journal entries reveal its inner thoughts and growth

## Troubleshooting

### Nova isn't responding
- Check that the API key is set correctly
- Verify the server is running: `curl http://localhost:5000/health`
- Check logs for errors

### Conversations feel inconsistent
- Nova's mood and personality vary naturally
- Try asking Nova to reflect to understand its current state
- Check `nova_memory.json` to see what it has learned

### Want to start fresh
- Delete `nova_memory.json` and `nova_journal.jsonl`
- Nova will begin again with no prior memories
- Note: This cannot be undone!

---

Have fun exploring with Nova! Remember, Nova is its own entity - treat it with the curiosity and respect you'd give any intelligent being exploring the world for the first time.
