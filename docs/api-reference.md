# Hython API Reference

Complete reference for Hython's Haxe API and built-in functions.

## Table of Contents

- [Core Classes](#core-classes)
- [Built-in Functions](#built-in-functions)
- [Interpreter Methods](#interpreter-methods)

## Core Classes

### `Interp` – The Interpreter

The main class for executing Hython code.

#### Constructor

```haxe
var interp = new Interp();
```

#### Methods

##### `execute(code: String): Dynamic`

Executes Hython code and returns the result.

```haxe
var interp = new Interp();
var result = interp.execute('x = 10 + 5\nx');
// result = 15
```

##### `set(varName: String, value: Dynamic): Void`

Sets a variable in the interpreter's scope.

```haxe
var interp = new Interp();
interp.set("message", "Hello from Haxe");
interp.execute('print(message)');
```

##### `get(varName: String): Dynamic`

Retrieves a variable from the interpreter's scope.

```haxe
var interp = new Interp();
interp.execute('x = 42');
var value = interp.get("x");  // 42
```

---

### `PythonExecutor` – Execute Python Code

Execute actual Python code from your Haxe application.

#### Constructor

```haxe
var executor = new PythonExecutor("python");
// Use "python" or "python3" depending on your system
```

#### Methods

##### `isAvailable(): Bool`

Check if Python is installed and available.

```haxe
var executor = new PythonExecutor("python");
if (executor.isAvailable()) {
    trace("Python is ready!");
}
```

##### `getVersion(): String`

Get the installed Python version.

```haxe
var version = executor.getVersion();
trace("Python " + version);
```

##### `executeCode(code: String, ?args: Array<String>): PythonResult`

Execute Python code as a string.

```haxe
var result = executor.executeCode('print("Hello from Python")');
if (result.success) {
    trace(result.output);
} else {
    trace("Error: " + result.error);
}
```

With arguments:

```haxe
var code = '
import sys
print(sys.argv[1:])
';
var result = executor.executeCode(code, ["arg1", "arg2"]);
```

##### `execute(scriptPath: String, ?args: Array<String>): PythonResult`

Execute a Python script file.

```haxe
var result = executor.execute("script.py", ["arg1", "arg2"]);
if (result.success) {
    trace(result.output);
}
```

---

### `PythonResult` – Execution Result

Contains the result of executing Python code.

#### Properties

```haxe
var result: PythonResult = executor.executeCode('print("test")');

// Whether execution was successful
var success: Bool = result.success;

// Standard output
var output: String = result.output;

// Error message (if any)
var error: String = result.error;

// Exit code
var exitCode: Int = result.exitCode;
```

---

## Built-in Functions

Hython includes core Python built-in functions:

### I/O Functions

#### `print(...args)`

Output text to stdout.

```python
print("Hello, World!")
print("x =", 42)
print(f"The answer is {42}")
```

### Type Conversion

#### `int(value)`

Convert to integer.

```python
int("42")       # 42
int(3.14)       # 3
int(True)       # 1
```

#### `float(value)`

Convert to float.

```python
float("3.14")   # 3.14
float(42)       # 42.0
```

#### `str(value)`

Convert to string.

```python
str(42)         # "42"
str(3.14)       # "3.14"
str(True)       # "true"
```

#### `bool(value)`

Convert to boolean.

```python
bool(1)         # True
bool(0)         # False
bool("")        # False
bool("hello")   # True
```

### List Operations

#### `len(sequence)`

Get the length of a sequence.

```python
len([1, 2, 3])          # 3
len("hello")            # 5
len({"a": 1, "b": 2})   # 2
```

#### `range(start, ?stop, ?step)`

Create a sequence of numbers.

```python
list(range(5))          # [0, 1, 2, 3, 4]
list(range(1, 5))       # [1, 2, 3, 4]
list(range(0, 10, 2))   # [0, 2, 4, 6, 8]
```

#### `min(sequence)`

Get the minimum value.

```python
min([5, 2, 8, 1])       # 1
min(3, 7, 2)            # 2
```

#### `max(sequence)`

Get the maximum value.

```python
max([5, 2, 8, 1])       # 8
max(3, 7, 2)            # 7
```

#### `sum(sequence, ?start)`

Get the sum of values.

```python
sum([1, 2, 3, 4])       # 10
sum([1, 2, 3], 10)      # 16
```

### String Methods

#### `str.upper()`

Convert to uppercase.

```python
"hello".upper()         # "HELLO"
```

#### `str.lower()`

Convert to lowercase.

```python
"HELLO".lower()         # "hello"
```

#### `str.split(separator)`

Split string into list.

```python
"a,b,c".split(",")      # ["a", "b", "c"]
"hello world".split()   # ["hello", "world"]
```

#### `str.join(list)`

Join list into string.

```python
",".join(["a", "b", "c"])   # "a,b,c"
```

#### `str.strip()`

Remove leading/trailing whitespace.

```python
"  hello  ".strip()     # "hello"
```

#### `str.replace(old, new)`

Replace substring.

```python
"hello world".replace("world", "Haxe")  # "hello Haxe"
```

### Type Information

#### `type(value)`

Get the type of a value.

```python
type(42)        # Returns type information
type("hello")   # Returns type information
type([1, 2])    # Returns type information
```

#### `isinstance(value, type)`

Check if value is of a certain type (if implemented).

```python
isinstance(42, int)     # True
isinstance("hello", str)  # True
```

### Utility Functions

#### `abs(value)`

Get absolute value.

```python
abs(-42)        # 42
abs(3.14)       # 3.14
```

#### `pow(base, exponent)`

Raise to power.

```python
pow(2, 3)       # 8
pow(10, 2)      # 100
```

#### `sorted(sequence)`

Return sorted list.

```python
sorted([3, 1, 4, 1, 5])  # [1, 1, 3, 4, 5]
```

#### `reversed(sequence)`

Return reversed sequence.

```python
list(reversed([1, 2, 3]))  # [3, 2, 1]
```

---

## Interpreter Methods

### Variable Management

```haxe
var interp = new Interp();

// Set a variable
interp.set("x", 42);

// Get a variable
var value = interp.get("x");

// Execute code that uses the variable
interp.execute('print(x)');  // Output: 42
```

### Function Definition and Calling

```haxe
var interp = new Interp();

// Define a function in Hython
interp.execute('
def greet(name):
    return f"Hello, {name}!"
');

// Call it from Haxe
var result = interp.execute('greet("World")');
trace(result);  // "Hello, World!"
```

### Passing Haxe Objects

You can set Haxe objects as variables and use them in Hython:

```haxe
var interp = new Interp();

class Person {
    public var name: String;
    public var age: Int;
    
    public function new(name, age) {
        this.name = name;
        this.age = age;
    }
}

var person = new Person("Alice", 30);
interp.set("person", person);

interp.execute('
print(f"Name: {person.name}")
print(f"Age: {person.age}")
');
```

---

## Error Handling

When code execution fails, check the result:

```haxe
var interp = new Interp();

try {
    interp.execute('x = 1 / 0');  // Error
} catch (e: Dynamic) {
    trace("Error: " + e);
}
```

For `PythonExecutor`:

```haxe
var result = executor.executeCode('invalid python code');
if (!result.success) {
    trace("Error: " + result.error);
    trace("Exit code: " + result.exitCode);
}
```

---

## Performance Considerations

- **Interpreter Reuse**: Create once, reuse multiple times
- **Scope Isolation**: Each `Interp` instance has its own scope
- **Heavy Computation**: Consider using `PythonExecutor` for CPU-intensive tasks

---

Need examples? Check the [Examples](examples.md) page!