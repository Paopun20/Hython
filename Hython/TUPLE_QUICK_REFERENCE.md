# Hython Tuple Support - Quick Reference Guide

## Quick Start

### Creating Tuples
```python
empty = ()                          # Empty tuple
single = (42,)                      # Single element (trailing comma required!)
pair = (1, 2)                       # Two elements
mixed = (1, "hello", 3.14, True)   # Mixed types
nested = ((1, 2), (3, 4))          # Nested tuples
```

### Accessing Elements
```python
t = (10, 20, 30, 40)
first = t[0]        # 10
last = t[-1]        # 40
middle = t[1:3]     # (20, 30)
```

### Common Operations
```python
t1 = (1, 2)
t2 = (3, 4)

concat = t1 + t2    # (1, 2, 3, 4)
repeat = t1 * 3     # (1, 2, 1, 2, 1, 2)
length = len(t1)    # 2
```

### Unpacking
```python
x, y = (5, 10)
a, b, c = (1, 2, 3)
```

### Iteration
```python
for value in (1, 2, 3):
    print(value)
```

## Method Reference

| Method | Purpose | Example |
|--------|---------|---------|
| `len(t)` | Get tuple size | `len((1,2,3))` → 3 |
| `t.count(x)` | Count occurrences | `(1,2,2,3).count(2)` → 2 |
| `t.index(x)` | Find first index | `(1,2,2,3).index(2)` → 1 |
| `tuple(x)` | Convert to tuple | `tuple([1,2,3])` → (1,2,3) |
| `list(t)` | Convert to list | `list((1,2,3))` → [1,2,3] |

## Operator Reference

| Operation | Example | Result |
|-----------|---------|--------|
| Indexing | `t[0]` | First element |
| Negative indexing | `t[-1]` | Last element |
| Slicing | `t[1:3]` | Elements 1-2 |
| Concatenation | `t1 + t2` | Combined tuple |
| Repetition | `t * 3` | Tuple repeated 3 times |
| Membership | `x in t` | Boolean (True/False) |
| Not membership | `x not in t` | Boolean (True/False) |
| Equality | `t1 == t2` | Boolean comparison |
| Inequality | `t1 != t2` | Boolean comparison |

## Common Patterns

### Return Multiple Values
```python
def get_point():
    return (10, 20)

x, y = get_point()
```

### Swap Variables
```python
a, b = 5, 10
a, b = b, a  # Swap
```

### Process Pairs
```python
pairs = [(1, 2), (3, 4), (5, 6)]
for x, y in pairs:
    print(x + y)
```

### With Enumerate
```python
items = ("a", "b", "c")
for index, item in enumerate(items):
    print(f"{index}: {item}")
```

## Important Notes

### Single Element Tuples
- **Correct:** `(42,)` — includes trailing comma
- **Incorrect:** `(42)` — just 42 in parentheses

### Immutability
Tuples cannot be modified after creation:
```python
t = (1, 2, 3)
# t[0] = 10  # ERROR!
```

### Unpacking
Must match number of elements:
```python
a, b = (1, 2, 3)  # ERROR! Too many values
```

### Type Checking
```python
type((1, 2, 3))  # Returns "tuple"
isinstance((1, 2, 3), tuple)  # Check type
```

## Slicing Quick Reference

```python
t = (0, 1, 2, 3, 4, 5)

t[1:4]      # (1, 2, 3)       - from index 1 to 3
t[:3]       # (0, 1, 2)       - first 3 elements
t[2:]       # (2, 3, 4, 5)    - from index 2 onwards
t[::2]      # (0, 2, 4)       - every 2nd element
t[1::2]     # (1, 3, 5)       - every 2nd, starting at 1
t[-3:]      # (3, 4, 5)       - last 3 elements
t[:-2]      # (0, 1, 2, 3)    - all but last 2
```

## Boolean Evaluation

```python
if (1, 2, 3):      # True - non-empty
    pass

if ():             # False - empty
    pass
```

## Type Conversion

```python
# From list
tuple([1, 2, 3])        # (1, 2, 3)

# From string
tuple("abc")            # ("a", "b", "c")

# From None
tuple(None)             # ()
tuple()                 # () - explicit empty

# To list
list((1, 2, 3))         # [1, 2, 3]
```

## Error Handling

```python
t = (1, 2, 3)

# Index out of range
try:
    x = t[10]
except:
    print("Index error!")

# Value not found
try:
    x = t.index(99)
except:
    print("Value not found!")

# Wrong unpacking count
try:
    a, b = (1, 2, 3)  # Too many values!
except:
    print("Unpacking error!")
```

## Performance Tips

- Indexing is O(1) - fast access
- Slicing is O(n) - creates new tuple
- Iteration is O(n) - go through all elements
- Membership test is O(n) - check each element
- Concatenation is O(n+m) - proportional to sizes

## Integration with Other Types

### With Lists
```python
items = [1, 2, 3]
t = tuple(items)        # Convert list to tuple
```

### With Dictionaries
```python
# Use tuples as dictionary keys (if hashable)
locations = {(0, 0): "origin", (1, 1): "diagonal"}
```

### With Functions
```python
def process(*args):     # args is a tuple
    return sum(args)

result = process(1, 2, 3, 4)  # 10
```

### With List Comprehensions
```python
t = (1, 2, 3)
doubled = [x * 2 for x in t]  # [2, 4, 6]
```

## Helpful Resources

- Full documentation: See `TUPLE_SUPPORT.md`
- Implementation details: See `TUPLE_IMPLEMENTATION_SUMMARY.md`
- Test examples: See `tests/TestTuple.hx`
- Python tuples: https://docs.python.org/3/tutorial/datastructures.html#tuples-and-sequences
