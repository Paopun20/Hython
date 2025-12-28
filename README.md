# Hython Interpreter
Hython is a Python scripting interpreter written in Haxe.

It’s designed for:
* working on any platform that you want
* working with Haxe/Haxeflixel projects
* lightweight and fast, with a small memory used and fast execution speed at the (maybe) seed of light
* easy to integrate with Haxe projects

> ⚠️ This is **not CPython**. It’s a Python language implemented on top of Haxe, and not a replacement for CPython and nor bindings to CPython.

## Usage

### Basic Usage

```haxe
import paopao.hython.Parser;
import paopao.hython.Interp;

// Simple execution
var code = "
def greet(name):
    return 'Hello, ' + name + '!'

print(greet('World'))
";

var parser = new Parser();
var expr = parser.parseString(code);
var interp = new Interp();
interp.execute(expr);
```

### Advanced Usage - Calling Specific Functions

```haxe
// Define your Python-like code
var code = "
def add(a, b):
    return a + b

def multiply(a, b):
    return a * b

def main(x, y):
    sum = add(x, y)
    product = multiply(x, y)
    print('Sum:', sum)
    print('Product:', product)
    return {'sum': sum, 'product': product}
";

// Parse and execute to define functions
var parser = new Parser();
var expr = parser.parseString(code);
var interp = new Interp();
interp.execute(expr);

// Call specific functions with arguments
var result = interp.calldef("main", [10, 5]);
// Output:
// Sum: 15
// Product: 50

// Call individual functions
var sum = interp.calldef("add", [7, 3]);      // Returns 10
var product = interp.calldef("multiply", [4, 6]); // Returns 24
```

### Setting Variables from Haxe

```haxe
var interp = new Interp();

// Set variables before executing code
interp.variables.set("myValue", 42);
interp.variables.set("config", {debug: true, version: "1.0"});

var code = "
def process():
    print('Value:', myValue)
    print('Debug mode:', config['debug'])
    return myValue * 2
";

var parser = new Parser();
interp.execute(parser.parseString(code));
var result = interp.calldef("process", []); // Returns 84
```

### Error Handling

```haxe
var interp = new Interp();

// Set custom error handler
interp.errorHandler = function(error) {
    trace("Script error: " + error);
    // Handle error gracefully
};

// Configure interpreter
interp.maxDepth = 100;  // Maximum recursion depth
interp.allowStaticAccess = true;  // Allow static access
interp.allowClassResolve = true;  // Allow class instantiation

var code = "
def risky_function():
    # This might cause an error
    return undefined_variable
";

try {
    var parser = new Parser();
    interp.execute(parser.parseString(code));
    interp.calldef("risky_function", []);
} catch (e:Dynamic) {
    trace("Caught error: " + e);
}
```

## Features

### Python-Style Syntax

- `def` function definitions with default arguments
- Python operators: `and`, `or`, `not`, `in`, `not in`, `is`, `is not`
- List comprehensions: `[x * 2 for x in range(10) if x % 2 == 0]`
- Dictionary comprehensions: `{x: x**2 for x in range(5)}`
- Slicing: `my_list[1:5]`, `my_string[::2]`
- Tuple support: `(1, 2, 3)` (it have bug I know, but it's not fixed yet at Tuple Unpacking)

### Built-in Functions

Hython includes Python-compatible built-in functions:

**Type Conversion:**

- `int()`, `float()`, `str()`, `bool()`
- `list()`, `dict()`, `type()`

**Numeric Functions:**

- `abs()`, `min()`, `max()`, `sum()`
- `round()`, `pow()`, `sqrt()`

**Sequence Functions:**

- `len()`, `range()`, `enumerate()`
- `sorted()`, `reversed()`, `zip()`

**Logic Functions:**

- `any()`, `all()`, `isinstance()`

**String Functions:**

- `ord()`, `chr()`

**I/O Functions:**

- `print()`

### Example: Complete Script

```haxe
var code = "
# Calculate fibonacci numbers
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

def main(count):
    results = [fibonacci(i) for i in range(count)]
    print('Fibonacci sequence:', results)
    return results

# Helper function
def sum_fibonacci(count):
    return sum([fibonacci(i) for i in range(count)])
";

var parser = new Parser();
var interp = new Interp();
interp.execute(parser.parseString(code));

// Call functions
var sequence = interp.calldef("main", [10]);
var total = interp.calldef("sum_fibonacci", [10]);

trace("Sequence: " + sequence);  // [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
trace("Sum: " + total);           // 88
```

## API Reference

### Interp Class

#### Methods

- `new()` - Create a new interpreter instance
- `execute(expr:Expr):Dynamic` - Execute parsed expression tree
- `calldef(name:String, args:Array<Dynamic>):Dynamic` - Call a defined function by name
- `getdef(name:String):Bool` - Check if a function is defined
- `setVar(name:String, value:Dynamic):Dynamic` - Set a variable
- `getVar(name:String):Dynamic` - Get a variable
- `delVar(name:String):Dynamic` - Delete a variable
- `stop()`: Stop the interpreter


#### Properties

- `variables:Map<String, Dynamic>` - Global variable storage
- `errorHandler:Error->Void` - Custom error handler
- `maxDepth:Int` - Maximum recursion depth (default: 1000)
- `allowStaticAccess:Bool` - Allow static field access (default: true)
- `allowClassResolve:Bool` - Allow class instantiation (default: true)

### Parser Class

#### Methods

- `new()` - Create a new parser instance
- `parseString(code:String):Expr` - Parse Python-like code into expression tree

## Origin
This project is a fork of **NebulaStellaNova’s pythonscript**.\
I saw it, liked the idea, and decided to push it further. :\
(Is it a fork, or a complete rewrite?)

## License

[MIT](LICENSE.md)