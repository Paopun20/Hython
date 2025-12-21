# Hython Language Guide

A comprehensive guide to Hython's syntax and features.

## Table of Contents

- [Basic Syntax](#basic-syntax)
- [Data Types](#data-types)
- [Operators](#operators)
- [Control Flow](#control-flow)
- [Functions](#functions)
- [Collections](#collections)
- [Advanced Features](#advanced-features)

## Basic Syntax

### Comments

Use `#` to start a comment:

```python
# This is a comment
x = 10  # Inline comment
```

### Indentation

Hython uses Python-style indentation for code blocks:

```python
if x > 5:
    print("x is greater than 5")
    if x > 10:
        print("x is also greater than 10")
```

### Strings

Strings can use single or double quotes:

```python
str1 = 'Hello'
str2 = "World"
str3 = 'It\'s working'
```

### String Formatting

Use f-strings for string interpolation:

```python
name = "Haxe"
age = 5
message = f"Hello {name}, you are {age} years old"
print(message)
```

## Data Types

### Numbers

Hython supports both integers and floating-point numbers:

```python
x = 42          # Integer
y = 3.14        # Float
z = -10         # Negative number
```

### Booleans

`True` and `False` are boolean values:

```python
is_active = True
is_deleted = False
```

### None

`None` represents the absence of a value:

```python
result = None
if result is None:
    print("Result is empty")
```

### Lists

Ordered collections of values:

```python
numbers = [1, 2, 3, 4, 5]
mixed = [1, "hello", 3.14, True]
empty = []

# Accessing elements (0-indexed)
first = numbers[0]  # 1
last = numbers[-1]  # 5

# List operations
numbers.append(6)
length = len(numbers)
```

### Dictionaries

Key-value pairs:

```python
person = {
    "name": "Alice",
    "age": 30,
    "city": "New York"
}

# Accessing values
name = person["name"]

# Adding new key-value pair
person["job"] = "Engineer"
```

## Operators

### Arithmetic

```python
a = 10
b = 3

sum_result = a + b         # 13
diff = a - b               # 7
product = a * b            # 30
quotient = a / b           # 3.333...
floor_div = a // b         # 3
remainder = a % b          # 1
power = a ** b             # 1000
```

### Comparison

```python
x = 10
y = 20

x == y          # False
x != y          # True
x < y           # True
x > y           # False
x <= y          # True
x >= y          # False
```

### Logical

```python
True and False              # False
True or False               # True
not True                    # False

x = 10
x > 5 and x < 20           # True
```

### Membership

```python
numbers = [1, 2, 3, 4, 5]
2 in numbers                # True
10 in numbers               # False

person = {"name": "Alice", "age": 30}
"name" in person            # True
```

## Control Flow

### If/Elif/Else

```python
score = 85

if score >= 90:
    print("Grade: A")
elif score >= 80:
    print("Grade: B")
elif score >= 70:
    print("Grade: C")
else:
    print("Grade: F")
```

### For Loops

```python
# Loop through a range
for i in range(5):
    print(i)  # 0, 1, 2, 3, 4

# Loop through a list
fruits = ["apple", "banana", "cherry"]
for fruit in fruits:
    print(fruit)

# Loop through a dictionary
person = {"name": "Alice", "age": 30}
for key in person:
    print(f"{key}: {person[key]}")
```

### While Loops

```python
count = 0
while count < 5:
    print(count)
    count = count + 1
```

### Break and Continue

```python
# Break: exit the loop
for i in range(10):
    if i == 5:
        break
    print(i)

# Continue: skip to next iteration
for i in range(5):
    if i == 2:
        continue
    print(i)  # 0, 1, 3, 4
```

## Functions

### Function Definition

```python
def greet(name):
    return f"Hello, {name}!"

result = greet("World")
print(result)
```

### Multiple Parameters

```python
def add(a, b):
    return a + b

def calculate(x, y, operation):
    if operation == "add":
        return x + y
    elif operation == "subtract":
        return x - y
    elif operation == "multiply":
        return x * y
    else:
        return None
```

### Default Parameters

```python
def greet(name="Guest"):
    return f"Hello, {name}!"

print(greet())           # Hello, Guest!
print(greet("Alice"))    # Hello, Alice!
```

### Lambda Functions

Anonymous functions for simple operations:

```python
square = lambda x: x * x
print(square(5))  # 25

add = lambda x, y: x + y
print(add(3, 4))  # 7
```

### Variable Scope

Variables defined inside a function are local:

```python
x = 10  # Global

def modify():
    x = 20  # Local
    print(x)  # 20

modify()
print(x)  # 10 (unchanged)
```

## Collections

### List Methods

```python
numbers = [3, 1, 4, 1, 5]

numbers.append(9)        # Add to end
numbers.insert(0, 2)     # Insert at position
length = len(numbers)    # Get length
```

### Dictionary Operations

```python
data = {"a": 1, "b": 2}

value = data["a"]        # Get value
data["c"] = 3            # Add/update
"a" in data              # Check if key exists
keys = list(data.keys()) # Get all keys (if implemented)
```

### Built-in Functions

```python
# Type conversion
int("42")
float("3.14")
str(100)

# List operations
len([1, 2, 3])           # 3
min([5, 2, 8, 1])        # 1
max([5, 2, 8, 1])        # 8
sum([1, 2, 3, 4])        # 10

# Range
for i in range(5):       # 0 to 4
    print(i)

# String operations
"hello".upper()          # "HELLO"
"HELLO".lower()          # "hello"
```

## Advanced Features

### List Comprehensions

Create lists using a compact syntax:

```python
squares = [x * x for x in range(5)]
# [0, 1, 4, 9, 16]

evens = [x for x in range(10) if x % 2 == 0]
# [0, 2, 4, 6, 8]
```

### Multiple Assignment

```python
x, y = 10, 20
a, b, c = [1, 2, 3]

# Swapping
x, y = y, x
```

### Type Checking

```python
x = 42
type(x)  # Should return type info

isinstance(x, int)  # Check if x is an integer
```

### Error Handling

Try-catch blocks (if implemented):

```python
try:
    result = 10 / 0
except:
    print("Error occurred")
```

---

## Hython vs Python

While Hython follows Python syntax, there are important differences:

| Feature | Hython | Python |
|---------|--------|--------|
| Classes | ❌ Not supported | ✅ Supported |
| Imports | ⚠️ Limited | ✅ Full support |
| Decorators | ❌ Not supported | ✅ Supported |
| Generators | ❌ Not supported | ✅ Supported |
| Async/Await | ❌ Not supported | ✅ Supported |
| Standard Library | ⚠️ Limited | ✅ Full stdlib |

For complex Python code, consider using `PythonExecutor` to call actual Python.

---

Ready to see practical examples? Check out the [Examples](examples.md) page!
