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
- **More Python Syntax/Features/Keywords**: Hython will support more Python features it don't have in hython, such as defcall("yes", var="input"), and more.
- **Documentation**: Hython will have comprehensive documentation, making it easier for developers to learn and use.

## Usage

see [here](./Usage.md) for more information.

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

## Limitations

Compared to CPython, Hython currently has the following limitations:

- The `import` keyword only supports Haxe libraries; Python module imports are not available.
- No type annotations or static type checking.
- No support for decorators.
- No async/await support.
- No generator functions (`yield`).
- Every variable is global (no local).
- Partial Python syntax and semantics coverage.

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
