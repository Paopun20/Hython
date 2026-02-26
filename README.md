# Hython Interpreter

Hython is a Python interpreter written in Haxe.

It’s designed for:
- working on any platform you want
- working with Haxe/Haxeflixel projects
- easy integration with Haxe projects

> This project is not bind to CPython, btw.

## Features

- **Lightweight**: Hython is designed to be lightweight, with a small memory footprint and fast execution speed, maybe at the speed of light (~4 times faster than CPython in cpp target).
- **Easy Integration**: Hython integrates easily with Haxe projects, making it a great choice for Haxe developers.
- **Own Runtime System**: Hython uses a own runtime system, to make it faster and more efficient.

## Features to be added (You can help! by contributing to the project)

- **Improved Error Handling**: Hython will have improved error handling, providing more detailed error messages and better error reporting.
- **Enhanced Performance**: Hython will be optimized for performance, with faster execution times and reduced memory usage.
- **More Python Syntax/Features/Keywords**: Hython will support more Python features it don't have in hython, such as defcall("yes", var="input"), and more.
- **Documentation**: Hython API will have comprehensive documentation, making it easier for developers to learn and use.

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

### Built-in Modules

- `math`
- `os`
- `random`
- `json`
- `datetime`
- `re`

> Python module imports are hardcoding it.

## Limitations

> [!NOTE]: It has quite a few limitations, but it's usable.

Compared to CPython, Hython currently has several limitations. The `import` keyword is BIG buggy; Hython does not support bytecode generation or execution, and there is no type annotation or static type checking system. Decorators and async/await syntax are not supported, and generator functions using `yield` are not available.

Additionally, Hython has limited support for dunder methods—currently only `__init__` on classes, `__name__` on root, and `__file__` on root are implemented. Every variable in Hython is treated as global with no local scope support. Finally, Hython provides only partial Python syntax and semantics coverage, meaning some Python features and behaviors may not work as expected or may not be implemented at all.

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
- `stop()`: Stop the interpreter and python code can't handle by trying or catching errors and become unusable.

#### Properties

- `maxDepth:Int` - Maximum recursion depth (default: 1000)
- `allowImport:Bool` - Allow importing modules (default: true)
- `allowClassResolve:Bool` - Allow class instantiation (default: true)

### Parser Class

#### Methods

- `new()` - Create a new parser instance
- `parseString(code:String):Expr` - Parse Python code into expression tree

## Origin

Hython was originally based on **NebulaStellaNova’s pythonscript**.

## Contributing

Contributions are welcome! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) file for details on how to contribute.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
