# Hython Examples

Practical examples demonstrating Hython's capabilities.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Game Scripting](#game-scripting)
- [Data Processing](#data-processing)
- [Function Callbacks](#function-callbacks)
- [Interop with Haxe](#interop-with-haxe)
- [Python Integration](#python-integration)

## Basic Usage

### Hello World

```haxe
import hython.Interp;

class Main {
    static function main() {
        var interp = new Interp();
        interp.execute('print("Hello, Hython!")');
    }
}
```

### Variables and Arithmetic

```haxe
var interp = new Interp();

interp.execute('
x = 10
y = 20
z = x + y
print(f"Result: {z}")
');
```

### Conditional Logic

```haxe
var interp = new Interp();

interp.execute('
age = 25
if age >= 18:
    print("You are an adult")
else:
    print("You are a minor")
');
```

---

## Game Scripting

### NPC Dialogue System

A simple dialogue system for games:

```haxe
import hython.Interp;

class DialogueSystem {
    var interp: Interp;
    
    public function new() {
        interp = new Interp();
        setupDialogueScript();
    }
    
    function setupDialogueScript() {
        interp.execute('
def get_dialogue(npc_name, mood):
    dialogues = {
        "happy": "Im feeling great today!",
        "sad": "I dont feel so good...",
        "angry": "Leave me alone!"
    }
    
    if npc_name == "merchant":
        return "Welcome to my shop!"
    elif npc_name == "guard":
        return "State your business!"
    else:
        return dialogues.get(mood, "Hello there")

def get_npc_response(player_choice, npc_type):
    responses = {
        "greet": "Hello!",
        "trade": "What are you buying?",
        "fight": "You dare challenge me?!"
    }
    return responses.get(player_choice, "...")
');
    }
    
    public function getDialogue(npcName: String, mood: String): String {
        return interp.execute(f'get_dialogue("{npcName}", "{mood}")');
    }
    
    public function respondTo(choice: String, npcType: String): String {
        return interp.execute(f'get_npc_response("{choice}", "{npcType}")');
    }
}
```

### Level Configuration

Describe game levels using Hython:

```haxe
var interp = new Interp();

interp.execute('
def create_level(name):
    levels = {
        "forest": {
            "enemies": 5,
            "difficulty": 2,
            "rewards": 100,
            "bosses": 0
        },
        "dungeon": {
            "enemies": 15,
            "difficulty": 5,
            "rewards": 500,
            "bosses": 1
        }
    }
    return levels.get(name, {})

forest_config = create_level("forest")
print(f"Forest: {forest_config["enemies"]} enemies")
');
```

---

## Data Processing

### Statistical Analysis

```haxe
var interp = new Interp();

interp.execute('
def analyze_scores(scores):
    total = sum(scores)
    count = len(scores)
    average = total / count
    max_score = max(scores)
    min_score = min(scores)
    
    return {
        "total": total,
        "average": average,
        "max": max_score,
        "min": min_score,
        "count": count
    }

scores = [85, 92, 78, 95, 88]
stats = analyze_scores(scores)
print(f"Average: {stats["average"]}")
print(f"Max: {stats["max"]}")
');
```

### Data Transformation

```haxe
var interp = new Interp();

interp.execute('
def transform_data(raw_data):
    # Filter and transform data
    processed = []
    for item in raw_data:
        if item > 0:
            processed.append(item * 2)
    return processed

data = [1, -2, 3, -4, 5]
result = transform_data(data)
print(result)  # [2, 6, 10]
');
```

### CSV-like Processing

```haxe
var interp = new Interp();

interp.execute('
def parse_records(lines):
    records = []
    for line in lines:
        parts = line.split(",")
        records.append({
            "id": int(parts[0]),
            "name": parts[1],
            "value": float(parts[2])
        })
    return records

lines = [
    "1,Alice,100.5",
    "2,Bob,200.75",
    "3,Charlie,150.25"
]

records = parse_records(lines)
for record in records:
    print(f"{record["name"]}: {record["value"]}")
');
```

---

## Function Callbacks

### Event Handling

```haxe
class EventManager {
    var interp: Interp;
    
    public function new() {
        interp = new Interp();
    }
    
    public function registerHandler(eventType: String, handler: String) {
        interp.set(eventType + "_handler", handler);
    }
    
    public function fireEvent(eventType: String, data: Dynamic) {
        interp.set("event_data", data);
        interp.execute('
if ${eventType}_handler:
    result = ${eventType}_handler(event_data)
');
    }
}
```

### Filter Functions

```haxe
var interp = new Interp();

interp.execute('
def apply_filter(data, filter_func):
    result = []
    for item in data:
        if filter_func(item):
            result.append(item)
    return result

# Usage
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
is_even = lambda x: x % 2 == 0
evens = apply_filter(numbers, is_even)
print(evens)  # [2, 4, 6, 8, 10]
');
```

---

## Interop with Haxe

### Setting and Getting Variables

```haxe
var interp = new Interp();

// Set variables from Haxe
interp.set("haxe_message", "Hello from Haxe!");
interp.set("multiplier", 5);

// Use them in Hython
interp.execute('
result = multiplier * 10
print(haxe_message)
print(f"Result: {result}")
');

// Get results back
var finalResult = interp.get("result");
trace("Result from Hython: " + finalResult);  // 50
```

### Working with Arrays

```haxe
var interp = new Interp();

// Pass an array from Haxe
var colors = ["red", "green", "blue"];
interp.set("colors", colors);

interp.execute('
for color in colors:
    print(f"Color: {color}")
    
# Modify the list
colors.append("yellow")
');

// Access modified array
var updatedColors = interp.get("colors");
trace("Updated colors: " + updatedColors);
```

### Passing Custom Objects

```haxe
class GameEntity {
    public var name: String;
    public var health: Int;
    public var x: Float;
    public var y: Float;
    
    public function new(name: String, health: Int) {
        this.name = name;
        this.health = health;
        this.x = 0;
        this.y = 0;
    }
}

var interp = new Interp();
var entity = new GameEntity("Player", 100);
interp.set("entity", entity);

interp.execute('
print(f"Entity: {entity.name}")
print(f"Health: {entity.health}")
entity.x = 10
entity.y = 20
');

// Access modified object
trace("Entity position: " + entity.x + ", " + entity.y);
```

---

## Python Integration

### Using Python for Heavy Lifting

When you need real Python capabilities:

```haxe
import hython.PythonExecutor;

class ImageProcessor {
    var executor: PythonExecutor;
    
    public function new() {
        executor = new PythonExecutor("python");
    }
    
    public function processImage(inputPath: String, outputPath: String): Bool {
        var pythonCode = '
from PIL import Image

img = Image.open("$inputPath")
# Process image
img = img.rotate(90)
img = img.resize((512, 512))
img.save("$outputPath")
print("Image processed successfully")
';
        
        var result = executor.executeCode(pythonCode);
        return result.success;
    }
}
```

---

Ready to start building? Check the [Getting Started](getting-started.md) guide!