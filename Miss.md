# Remaining Missing Features in Hython

## Syntax

| Feature                         | Status                   |
| ------------------------------- | ------------------------ |
| Full f-strings with expressions | Basic support only       |
| Multiple except types           | Single except only       |
| Class inheritance (bases)       | Parsed but not evaluated |

## Built-in Functions

| Function         | Status          |
| ---------------- | --------------- |
| `open()`         | Not implemented |
| `map()`          | Not implemented |
| `filter()`       | Not implemented |
| `iter()`         | Not implemented |
| `slice()`        | Not implemented |
| `super()`        | Not implemented |
| `delattr()`      | Not implemented |
| `compile()`      | Not implemented |
| `eval()`         | Not implemented |
| `exec()`         | Not implemented |
| `breakpoint()`   | Not implemented |

## Built-in Types

| Type                   | Status             |
| ---------------------- | ------------------ |
| `bytes` / `bytearray`  | Basic literal only |
| `frozenset`            | Not implemented    |
| `complex`              | Not implemented    |
| `range` object         | Returns Array      |
| `memoryview`           | Not implemented    |
| `set` (as proper type) | Returns Array      |

## Modules

| Module        | Status          |
| ------------- | --------------- |
| `sys`         | Not implemented |
| `time`        | Not implemented |
| `collections` | Not implemented |
| `functools`   | Not implemented |
| `itertools`   | Not implemented |
| `statistics`  | Not implemented |
| `re`          | Partial         |

## Other

- Full async/await runtime (currently syntactic)
- Context managers (`__enter__`/`__exit__`)
- Descriptors
- Metaclasses
- Coroutines
- Full class inheritance MRO
- Threading
- Regular expressions (partial)
