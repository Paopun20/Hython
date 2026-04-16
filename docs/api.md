# API Reference

## Interp Class

### Interp Methods

| Method                                              | Description                       |
| --------------------------------------------------- | --------------------------------- |
| `new()`                                             | Create a new interpreter instance |
| `execute(expr:Expr):Dynamic`                        | Execute parsed expression tree    |
| `calldef(name:String, args:Array<Dynamic>):Dynamic` | Call a defined function           |
| `hasDef(name:String):Bool`                          | Check if a function is defined    |
| `setVar(name:String, value:Dynamic):Dynamic`        | Set a variable                    |
| `getVar(name:String):Dynamic`                       | Get a variable                    |
| `delVar(name:String):Dynamic`                       | Delete a variable                 |
| `stop()`                                            | Stop the interpreter              |

### Interp Properties

| Property            | Type | Default | Description               |
| ------------------- | ---- | ------- | ------------------------- |
| `maxDepth`          | Int  | 1000    | Maximum recursion depth   |
| `allowImport`       | Bool | true    | Allow importing modules   |
| `allowClassResolve` | Bool | true    | Allow class instantiation |

## Parser Class

### Parser Methods

| Method                          | Description                            |
| ------------------------------- | -------------------------------------- |
| `new()`                         | Create a new parser instance           |
| `parseString(code:String):Expr` | Parse Python code into expression tree |

## Built-in Functions

### Type Conversion

- `int()`, `float()`, `str()`, `bool()`
- `list()`, `dict()`, `type()`, `tuple()`

### Numeric Functions

- `abs()`, `min()`, `max()`, `sum()`
- `round()`, `pow()`, `sqrt()`
- `hex()`, `oct()`, `bin()`

### Sequence Functions

- `len()`, `range()`, `enumerate()`
- `sorted()`, `reversed()`, `zip()`
- `next()`

### Logic Functions

- `any()`, `all()`, `isinstance()`
- `hasattr()`, `getattr()`, `setattr()`, `callable()`

### Input/Output

- `print()`, `input()`

### Other

- `id()`, `format()`, `vars()`, `ord()`, `chr()`

## Built-in Modules

- `math` - Mathematical functions
- `os` - Operating system interface
- `random` - Random number generation
- `json` - JSON encoding/decoding
- `datetime` - Date and time handling
- `re` - Regular expressions
