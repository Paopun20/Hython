# Getting Started with Hython

This guide will help you set up and run your first Hython script.

## Installation

### Prerequisites

- **Haxe** (version 4.0 or later)
- Your Haxe project setup with a `haxelib.json`

### Adding Hython to Your Project

1. Install Hython via haxelib:

```bash
haxelib install hython
```

2. Add Hython to your project's `.hxml` file:

```
-lib hython
```

## Your First Script

### Basic Hello World

Create a Haxe file that imports Hython and executes a simple script:

```haxe
import hython.Interp;

class Main {
    static function main() {
        var interp = new Interp();
        interp.execute('
print("Hello, Hython!")
');
    }
}
```

### Running Haxe with Hython

Compile and run your Haxe project:

```bash
haxe build.hxml
```

## Core Classes

### `Interp` – The Main Interpreter

The `Interp` class is your gateway to executing Hython code.

```haxe
var interp = new Interp();
interp.execute('x = 10\nprint(x)');
```

### `PythonExecutor` – Call Python from Haxe

If you need to execute actual Python code alongside Hython:

```haxe
var executor = new PythonExecutor("python");
if (executor.isAvailable()) {
    var result = executor.executeCode('print("Hello from Python")');
    trace(result.output);
}
```

## Basic Hython Syntax

### Variables and Types

Hython uses dynamic typing, so no type declarations are needed:

```python
name = "Alice"
age = 30
pi = 3.14159
is_active = True
empty_list = []
```

### Print Statements

Output text using the `print()` function:

```python
print("Hello, World!")
x = 42
print(f"The answer is {x}")
```

### Control Flow

#### If/Elif/Else

```python
x = 10
if x > 20:
    print("x is greater than 20")
elif x == 10:
    print("x is exactly 10")
else:
    print("x is less than 20")
```

#### For Loops

```python
for i in range(5):
    print(i)

for item in [1, 2, 3]:
    print(item)
```

#### While Loops

```python
count = 0
while count < 5:
    print(count)
    count = count + 1
```

### Functions

Define reusable code with functions:

```python
def greet(name):
    return f"Hello, {name}!"

result = greet("Haxe")
print(result)
```

### Lists and Dictionaries

Work with collections:

```python
# Lists
numbers = [1, 2, 3, 4, 5]
print(numbers[0])

# Dictionaries
person = {
    "name": "Alice",
    "age": 30
}
print(person["name"])
```

## Next Steps

- Dive into the [Language Guide](language-guide.md) for comprehensive syntax documentation
- Check out [Examples](examples.md) for real-world use cases
- Review the [API Reference](api-reference.md) for all available functions and classes
- Learn about the [Architecture](architecture.md) to understand how Hython works

## Common Issues

### "Cannot find library hython"

Make sure you've installed hython via haxelib and added it to your `.hxml` file.

### Script Execution Errors

Check that your Hython code follows Python syntax rules. Use proper indentation and colons for blocks.

### Missing Built-in Functions

Hython supports core Python functions like `print()`, `len()`, `range()`, etc., but not all Python standard library functions.

---

Ready to learn more? Check out the [Language Guide](language-guide.md)!