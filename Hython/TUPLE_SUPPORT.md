# Hython Tuple Support - Complete Implementation Guide

## Overview

Hython now has **full support for Python-style tuples** with all standard operations, methods, and immutability semantics. Tuples are ordered, immutable collections that can contain mixed data types.

## Features Implemented

### 1. **Tuple Creation**
Tuples can be created using parentheses syntax:

```python
# Empty tuple
empty = ()

# Single element tuple (note the trailing comma!)
single = (42,)

# Multiple elements
coordinates = (10, 20)
mixed = (1, "hello", 3.14, True, None)

# Nested tuples
nested = ((1, 2), (3, 4))
```

### 2. **Tuple Indexing**
Access tuple elements by index, with support for negative indices:

```python
t = (10, 20, 30, 40)

# Positive indexing
first = t[0]    # 10
middle = t[1]   # 20

# Negative indexing
last = t[-1]    # 40
second_last = t[-2]  # 30

# Out of range raises IndexError
# value = t[10]  # ERROR: tuple index out of range
```

### 3. **Tuple Slicing**
Extract subsequences with full slice notation support:

```python
t = (0, 1, 2, 3, 4, 5)

# Basic slicing [start:end]
middle = t[1:4]    # (1, 2, 3)

# From start to index
first_three = t[:3]    # (0, 1, 2)

# From index to end
from_two = t[2:]   # (2, 3, 4, 5)

# With step [start:end:step]
even = t[::2]      # (0, 2, 4)
every_other = t[1::2]  # (1, 3, 5)

# Negative indices in slices
last_two = t[-2:]  # (4, 5)
```

### 4. **Tuple Operations**
Concatenate and repeat tuples:

```python
t1 = (1, 2)
t2 = (3, 4)

# Concatenation
combined = t1 + t2     # (1, 2, 3, 4)

# Repetition
repeated = t1 * 3      # (1, 2, 1, 2, 1, 2)
reversed_repeat = 2 * t1  # (1, 2, 1, 2)

# Repetition with zero
empty = t1 * 0     # ()
```

### 5. **Tuple Methods**

#### `len(tuple)`
Get the number of elements:
```python
t = (1, 2, 3, 4, 5)
size = len(t)  # 5
```

#### `tuple.count(value)`
Count occurrences of a value:
```python
t = (1, 2, 2, 3, 2, 4)
count = t.count(2)  # 3
```

#### `tuple.index(value)`
Find the index of the first occurrence:
```python
t = (10, 20, 30, 20)
idx = t.index(20)  # 1 (first occurrence)

# Raises ValueError if not found
# idx = t.index(99)  # ERROR
```

### 6. **Membership Testing**
Check if elements are in a tuple:

```python
t = (1, 2, 3, 4, 5)

# 'in' operator
is_in = 3 in t      # True
not_in = 10 in t    # False

# 'not in' operator
is_not_in = 10 not in t   # True
not_not_in = 3 not in t   # False
```

### 7. **Tuple Unpacking**
Assign tuple elements to multiple variables:

```python
# Simple unpacking
a, b = (1, 2)
a, b, c = (10, 20, 30)

# With parentheses
(x, y) = (5, 10)

# Implicit tuples (comma-based)
p, q = 100, 200
first, second, third = 1, 2, 3

# Swapping values
x = 5
y = 10
x, y = y, x  # x=10, y=5
```

### 8. **Type Conversion**
Convert to/from tuples:

```python
# Create from list
t = tuple([1, 2, 3])  # (1, 2, 3)

# Create from string
t = tuple("abc")      # ('a', 'b', 'c')

# Convert to list
t = (1, 2, 3)
l = list(t)          # [1, 2, 3]

# Type checking
t = (1, 2, 3)
type_name = type(t)  # "tuple"
```

### 9. **Iteration**
Iterate over tuple elements:

```python
t = (10, 20, 30, 40)

# Basic iteration
sum_val = 0
for value in t:
    sum_val += value
# sum_val = 100

# With enumerate
for index, value in enumerate(t):
    print(f"Index {index}: {value}")
```

### 10. **Tuple Comparisons**
Compare tuples for equality and inequality:

```python
t1 = (1, 2, 3)
t2 = (1, 2, 3)
t3 = (1, 2, 4)

# Equality
t1 == t2  # True
t1 != t3  # True

# Different lengths
(1, 2) == (1, 2, 3)  # False
```

### 11. **Boolean Context**
Tuples evaluate in boolean contexts:

```python
# Non-empty tuple is truthy
if (1, 2, 3):
    # This executes
    pass

# Empty tuple is falsy
if ():
    # This does NOT execute
    pass
else:
    # This executes
    pass
```

## Advanced Examples

### Returning Multiple Values from Functions
```python
def get_coordinates():
    return (10, 20)

x, y = get_coordinates()
distance = x * y  # 200
```

### Nested Structures
```python
data = [(1, 2), (3, 4), (5, 6)]
first_tuple = data[0]  # (1, 2)
first_value = first_tuple[0]  # 1
```

### Tuple Comprehension in List Comprehensions
```python
t = (1, 2, 3)
doubled = [x * 2 for x in t]  # [2, 4, 6]
```

### Using Tuples with Functions
```python
def process(*args):
    return sum(args)

result = process(1, 2, 3, 4)  # 10
```

## Implementation Details

### Key Classes
- **`Tuple`** - The main tuple class in `Objects.hx`
  - Immutable storage of elements
  - Full Python-compatible method implementations
  - Support for iteration and comparisons

### Key Methods in Interp.hx
- Binary operations (`+`, `*`) handle tuples specially
- `EArray` case handles tuple indexing
- `ESlice` case handles tuple slicing
- Membership operators (`in`, `not in`) support tuples
- `tuple()` built-in function for conversion

### Key Features
✅ Immutability (tuples are immutable)  
✅ Negative indexing and slicing  
✅ Tuple concatenation and repetition  
✅ All standard methods (count, index, len)  
✅ Unpacking support  
✅ Type conversion  
✅ Iteration and membership testing  
✅ Comparison operations  

## Performance Notes

Tuples in Hython are implemented using Haxe arrays internally but wrapped in the `Tuple` class for proper semantics:
- Indexing: O(1)
- Slicing: O(n) where n is the slice size
- Concatenation: O(n+m) where n,m are tuple sizes
- Membership testing: O(n)
- Iteration: O(n)

## Testing

Comprehensive tests are provided in `tests/TestTuple.hx` covering:
- Basic tuple creation
- Indexing (positive and negative)
- Slicing with various parameters
- Operations (concatenation, repetition)
- Methods (count, index, len)
- Membership testing
- Unpacking
- Type conversion
- Iteration
- Comparisons
- Edge cases

Run tests with:
```bash
haxe test.hxml
```

## Backward Compatibility

The implementation is fully backward compatible:
- Existing code using tuples continues to work
- The `tuple()` function is available for explicit conversion
- Tuple syntax is identical to Python
- No breaking changes to other Hython features

## Future Enhancements

Possible future improvements:
- Tuple hashing for use as dictionary keys
- More advanced unpacking patterns
- Performance optimizations for very large tuples
- Named tuples (if namedtuple support is added)

## Common Pitfalls

### Single Element Tuples
Remember the trailing comma for single-element tuples:
```python
single = (42,)    # Correct: tuple with one element
not_tuple = (42)  # This is just 42 in parentheses!
```

### Immutability
Tuples are immutable - you cannot modify elements:
```python
t = (1, 2, 3)
# t[0] = 10  # ERROR: Cannot assign to tuple
```

### Unpacking Length Mismatch
The number of variables must match the number of elements:
```python
a, b = (1, 2, 3)  # ERROR: too many values to unpack
x, y, z = (1, 2)  # ERROR: not enough values to unpack
```

## References

- Python Tuples: https://docs.python.org/3/tutorial/datastructures.html#tuples-and-sequences
- Haxe Standard Library: https://haxe.org/
