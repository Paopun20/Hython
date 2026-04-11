# Supported Features

## Python Syntax

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

!!! note
    Syntax is some as Python 3.1x, but some features from newer versions may be missing or partially supported.

## Dunder Methods

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

## Limitations

!!! warning
    Hython has quite a few limitations, but it's usable.
    Some has unlisted here, because I don't know implemented them yet, and I forgot to write them down.

- A lot non-important features are not implemented yet, such as `asyncio`, `threading`, `multiprocessing`, `socket`, `subprocess`, `os` module, etc.
