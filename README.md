# Hython Interpreter

Hython is a Python interpreter written in Haxe.

It's designed for:

- working on any platform you want
- working with Haxe/Haxeflixel projects
- easy integration with Haxe projects

> This project is not bind to CPython, btw.

## Features

- **Lightweight**: Hython is designed to be lightweight, with a small memory footprint and fast execution speed, maybe at the speed of light (~4 times faster than CPython in cpp target).
- **Easy Integration**: Hython integrates easily with Haxe projects, making it a great choice for Haxe developers.
- **Own Runtime System**: Hython uses a own runtime system, to make it faster and more efficient.

## Usage

see [here](./Usage.md) for more information.

## Features

### Python Syntax

- `def` function definitions with default arguments
- Python operators: `and`, `or`, `not`, `in`, `not in`, `is`, `is not`
- List comprehensions: `[x * 2 for x in range(10) if x % 2 == 0]`
- Dictionary comprehensions: `{x: x**2 for x in range(5)}`
- Set comprehensions: `{x * 2 for x in range(5)}`
- Slicing: `my_list[1:5]`, `my_string[::2]`
- Tuple support: `(1, 2, 3)`
- Multiple assignment: `a, b = 1, 2`
- Tuple unpacking: `a, b = (1, 2)`
- Set literals: `{1, 2, 3}`
- Walrus operator: `(x := 5)`
- `global` keyword for declaring global variables inside functions
- `nonlocal` keyword for declaring variables from enclosing scopes
- `yield` keyword for generator functions
- Type hints: `def greet(name: str) -> str:`, `List[int]`, `Callable[[int], str]`
- `try/except/finally` exception handling
- `raise` statement for throwing exceptions
- `match/case` pattern matching (Python 3.10+)
- `with` statement for context management
- `async/await` for asynchronous programming
- `...` (ellipsis) literal
- Bytes literals: `b"hello"`
- f-strings (basic support)
- Decorators: `@decorator` syntax
- Built-in decorators: `property()`, `staticmethod()`, `classmethod()`

### Dunder (It's is Magic) Methods

Hython supports the following dunder methods on classes:

- `__init__` - Constructor
- `__str__` - String representation (`str()`)
- `__repr__` - Representation
- `__len__` - Length (`len()`)
- `__add__` - Addition operator (`+`)
- `__sub__` - Subtraction operator (`-`)
- `__mul__` - Multiplication operator (`*`)
- `__truediv__` - Division operator (`/`)
- `__floordiv__` - Floor division (`//`)
- `__mod__` - Modulo operator (`%`)
- `__pow__` - Power operator (`**`)
- `__eq__` - Equality (`==`)
- `__ne__` - Not equal (`!=`)
- `__lt__` - Less than (`<`)
- `__gt__` - Greater than (`>`)
- `__le__` - Less than or equal (`<=`)
- `__ge__` - Greater than or equal (`>=`)
- `__contains__` - Membership test (`in`)
- `__getitem__` - Indexing (`obj[key]`)
- `__call__` - Callable objects

### Built-in Functions

Hython includes Python-compatible built-in functions:

**Type Conversion:**

- `int()`, `float()`, `str()`, `bool()`
- `list()`, `dict()`, `type()`, `tuple()`

**Numeric Functions:**

- `abs()`, `min()`, `max()`, `sum()`
- `round()`, `pow()`, `sqrt()`
- `hex()`, `oct()`, `bin()`

**Sequence Functions:**

- `len()`, `range()`, `enumerate()`
- `sorted()`, `reversed()`, `zip()`
- `next()` - get next value from iterator/generator

**Logic Functions:**

- `any()`, `all()`, `isinstance()`
- `hasattr()`, `getattr()`, `setattr()`, `callable()`

**Input/Output:**

- `print()`
- `input()`

**Other:**

- `id()`, `format()`, `vars()`, `ord()`, `chr()`

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

Compared to CPython, Hython currently has several limitations; Hython does not use bytecode generation, and there is no type annotation or static type checking system.

Additionally, Hython has limited support for some advanced Python features. Some Python features and behaviors may not work as expected or may not be implemented at all.

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

Hython was originally based on **NebulaStellaNova's pythonscript**.

## Contributing

Contributions are welcome! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) file for details on how to contribute.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
