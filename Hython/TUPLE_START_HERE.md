# 🎉 Hython Tuple Support - START HERE

Welcome! Tuple support has been **completely implemented** in Hython. This document will help you get started.

## What's New?

You can now use Python-style tuples in Hython with full support for:
- ✅ Creating tuples: `(1, 2, 3)`
- ✅ Indexing and slicing
- ✅ Concatenation and repetition
- ✅ Unpacking and methods
- ✅ All standard operations

## Quick Examples

```python
# Create tuples
point = (10, 20)
colors = ("red", "green", "blue")
mixed = (1, "hello", 3.14, True)

# Access elements
x = point[0]        # 10
last = point[-1]    # 20

# Slice them
middle = colors[1:3]  # ("green", "blue")

# Operations
t1 = (1, 2)
t2 = (3, 4)
combined = t1 + t2    # (1, 2, 3, 4)
repeated = t1 * 3     # (1, 2, 1, 2, 1, 2)

# Unpack them
x, y = (5, 10)
a, b, c = (1, 2, 3)

# Use methods
t = (1, 2, 2, 3)
t.count(2)    # 2
t.index(2)    # 1
len(t)        # 4
```

## Documentation

Choose what you need:

### 📚 For Quick Answers
→ **[TUPLE_QUICK_REFERENCE.md](TUPLE_QUICK_REFERENCE.md)**
- Quick syntax examples
- Method reference table
- Common patterns
- Troubleshooting

### 📖 For Comprehensive Guide
→ **[TUPLE_SUPPORT.md](TUPLE_SUPPORT.md)**
- Complete feature documentation
- All operations explained
- Advanced examples
- Performance notes

### 🔧 For Implementation Details
→ **[TUPLE_IMPLEMENTATION_SUMMARY.md](TUPLE_IMPLEMENTATION_SUMMARY.md)**
- What was changed
- How it works
- Test coverage

### ✅ For Status Report
→ **[TUPLE_COMPLETE.md](TUPLE_COMPLETE.md)**
- Feature checklist
- Quality metrics
- Known limitations

## Test Your Code

Run the comprehensive test suite:

```bash
haxe test.hxml
```

All 75+ tuple tests should pass!

## Common Tasks

### Create a Tuple
```python
# With values
t = (1, 2, 3)

# From a list
t = tuple([1, 2, 3])

# From a string
t = tuple("abc")  # ('a', 'b', 'c')

# Empty tuple
t = ()
```

### Access Elements
```python
t = (10, 20, 30, 40)
first = t[0]      # 10
last = t[-1]      # 40
middle = t[1:3]   # (20, 30)
```

### Modify Collections
```python
# Create new tuple by concatenation
new_t = t + (50,)

# Create new tuple by repetition
doubled = t * 2

# Create new tuple by slicing
subset = t[::2]
```

### Unpack Values
```python
# Simple unpacking
a, b = (1, 2)

# Multiple variables
x, y, z = (10, 20, 30)

# Swap values
a, b = b, a

# Return from function
def get_point():
    return (5, 10)
x, y = get_point()
```

### Use Methods
```python
t = (1, 2, 2, 3, 2)

# Count occurrences
count = t.count(2)    # 3

# Find index
index = t.index(2)    # 1

# Get length
size = len(t)         # 5

# Convert to list
lst = list(t)
```

## Important Notes

### Single Element Tuples
Remember the trailing comma!
```python
single = (42,)    # ✅ Correct - single element tuple
not_tuple = (42)  # ❌ Wrong - just 42 in parentheses
```

### Immutability
Tuples cannot be modified:
```python
t = (1, 2, 3)
# t[0] = 10  # ❌ ERROR - tuples are immutable
```

### Unpacking Must Match
```python
# ✅ Correct
a, b = (1, 2)

# ❌ Wrong - too many values
a, b = (1, 2, 3)

# ❌ Wrong - not enough values
a, b, c = (1, 2)
```

## Next Steps

1. **Read the quick reference:** [TUPLE_QUICK_REFERENCE.md](TUPLE_QUICK_REFERENCE.md)
2. **Try some examples:** See the test file at [tests/TestTuple.hx](tests/TestTuple.hx)
3. **Use tuples in your code!** They work just like in Python

## Support

If you have questions:

1. **Quick questions?** Check [TUPLE_QUICK_REFERENCE.md](TUPLE_QUICK_REFERENCE.md)
2. **How do I...?** Search [TUPLE_SUPPORT.md](TUPLE_SUPPORT.md)
3. **How does it work?** Read [TUPLE_IMPLEMENTATION_SUMMARY.md](TUPLE_IMPLEMENTATION_SUMMARY.md)
4. **See examples?** Check [tests/TestTuple.hx](tests/TestTuple.hx)

## Feature Matrix

| Feature | Status |
|---------|--------|
| Creating tuples | ✅ |
| Indexing | ✅ |
| Slicing | ✅ |
| Concatenation (+) | ✅ |
| Repetition (*) | ✅ |
| Methods (count, index, len) | ✅ |
| Unpacking | ✅ |
| Iteration | ✅ |
| Type conversion | ✅ |
| Membership (in/not in) | ✅ |
| Comparisons | ✅ |

## Examples by Use Case

### Return Multiple Values
```python
def get_user():
    return ("Alice", 30, "alice@example.com")

name, age, email = get_user()
```

### Swap Variables
```python
a = 5
b = 10
a, b = b, a  # Now a=10, b=5
```

### Working with Coordinates
```python
points = [(0, 0), (1, 1), (2, 2)]
for x, y in points:
    print(f"({x}, {y})")
```

### Function Arguments
```python
def distance(p1, p2):
    x1, y1 = p1
    x2, y2 = p2
    return ((x2-x1)**2 + (y2-y1)**2)**0.5

dist = distance((0, 0), (3, 4))  # 5.0
```

## Performance

Tuples are optimized for:
- **Fast indexing:** O(1)
- **Efficient iteration:** O(n)
- **Memory safe:** Immutable

## What's the Difference from Lists?

| Feature | List | Tuple |
|---------|------|-------|
| Syntax | `[1, 2, 3]` | `(1, 2, 3)` |
| Mutable | ✅ Yes | ❌ No |
| Iteration | ✅ Yes | ✅ Yes |
| Dict keys | ❌ No | ✅ Yes* |

*Future: Dict key support coming

## Troubleshooting

**Q: I get "tuple index out of range"**
A: Make sure your index is valid for the tuple size

**Q: Single element tuple not working**
A: Add a trailing comma: `(x,)` not `(x)`

**Q: Can't unpack values**
A: Check that the number of variables matches tuple elements

**Q: Modified a tuple but it didn't work**
A: Tuples are immutable. Create a new tuple instead

## Complete Features Implemented

✅ **Syntax & Creation**
- Tuple literals with parentheses
- Mixed data types
- Nested tuples
- Empty tuples

✅ **Access**
- Positive and negative indexing
- Full slicing with step
- Error handling

✅ **Operations**
- Concatenation with +
- Repetition with *
- Membership testing with in/not in

✅ **Methods**
- len() - get size
- count() - count items
- index() - find position

✅ **Unpacking**
- Simple assignment
- Multiple variables
- With functions

✅ **Integration**
- With lists: list(tuple), tuple(list)
- With strings: tuple(string)
- With iteration: for loops
- With functions: return values, parameters

## That's It!

You're ready to use tuples in Hython! 🎉

For more details, see the documentation files:
- Quick Reference: [TUPLE_QUICK_REFERENCE.md](TUPLE_QUICK_REFERENCE.md)
- Full Guide: [TUPLE_SUPPORT.md](TUPLE_SUPPORT.md)
- Implementation: [TUPLE_IMPLEMENTATION_SUMMARY.md](TUPLE_IMPLEMENTATION_SUMMARY.md)

Happy coding! 🚀
