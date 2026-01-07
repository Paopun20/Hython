# Hython Interpreter

Hython is a Python interpreter written in Haxe.

It’s designed for:
- working on any platform you want
- working with Haxe/Haxeflixel projects
- easy integration with Haxe projects

> This project is not bind to CPython, btw.

## Features

- **Lightweight**: Hython is designed to be lightweight, with a small memory footprint and fast execution speed, maybe at the speed of light.
- **Easy Integration**: Hython integrates easily with Haxe projects, making it a great choice for Haxe developers.
- **No Bytecode**: Hython uses a token system and lexer, eliminating the need for bytecode.

## Features to be added (You can help! by contributing to the project)

- **Improved Error Handling**: Hython will have improved error handling, providing more detailed error messages and better error reporting.
- **Enhanced Performance**: Hython will be optimized for performance, with faster execution times and reduced memory usage.
- **Threading Support**: Hython will support threading, allowing concurrent execution of tasks like python threads.
- **JIT Compilation**: Hython will support JIT compilation, allowing faster execution and reduced memory usage.
- **More Python Syntax/Features/Keywords**: Hython will support more Python features it don't have in hython, such as defcall("yes", var="input") and more.

## Usage

### Installation

To install Hython, you can use the following command:

```bash
haxelib install hython
```

Dev Build:

```bash
haxelib git hython https://github.com/Paopun20/hython.git
```

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
// Define your Python code
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
interp.setVar("myValue", 42);
interp.setVar("config", {debug: true, version: "1.0"});

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

## Features

### Python Syntax

- `def` function definitions with default arguments
- Python operators: `and`, `or`, `not`, `in`, `not in`, `is`, `is not`
- List comprehensions: `[x * 2 for x in range(10) if x % 2 == 0]` (it have bug I know, but it's not fixed yet at parse code)
- Dictionary comprehensions: `{x: x**2 for x in range(5)}` (it have bug I know, but it's not fixed yet at parse code)
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
- `calldef(name:String, args:Array<Dynamic>):Dynamic` - Call a defined function with name and arguments
- `getdef(name:String):Bool` - Check if a function is defined
- `setVar(name:String, value:Dynamic):Dynamic` - Set a variable
- `getVar(name:String):Dynamic` - Get a variable
- `delVar(name:String):Dynamic` - Delete a variable
- `stop()`: Stop the interpreter and python code can't handle by trying or catching errors

#### Properties

- `maxDepth:Int` - Maximum recursion depth (default: 1000)
- `allowStaticAccess:Bool` - Allow static field access (default: true)
- `allowClassResolve:Bool` - Allow class instantiation (default: true)

### Parser Class

#### Methods

- `new()` - Create a new parser instance
- `parseString(code:String):Expr` - Parse Python code into expression tree

## Origin

This project is built on top of **NebulaStellaNova’s pythonscript** as the template.

## Contributing

Contributions are welcome! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) file for details on how to contribute.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
