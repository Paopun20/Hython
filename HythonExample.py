# Hython Example - Python-inspired Scripting in Haxe
# Demonstrating Python built-in functions and features

# =============================================================================
# 1. Print Function
# =============================================================================

print("Hello, Hython!")
print("This is a test")

message = "Welcome to Hython"
print(message)


# =============================================================================
# 2. Type Conversion Functions
# =============================================================================

# Convert to string
num = 42
str_num = str(num)
print(str(num))

# Convert to integer
str_value = "123"
int_value = int(str_value)
print(int_value)

# Convert to float
float_value = float("3.14")
print(float_value)

# Convert to boolean
print(bool(1))
print(bool(0))
print(bool(""))
print(bool("hello"))


# =============================================================================
# 3. Length Function
# =============================================================================

# Length of string
name = "Hython"
print(len(name))

# Length of list
numbers = [1, 2, 3, 4, 5]
print(len(numbers))

# Length of dict
person = {"name": "Alice", "age": 25}
print(len(person))


# =============================================================================
# 4. Math Functions
# =============================================================================

# Absolute value
print(abs(-10))
print(abs(3.14))

# Minimum and maximum
print(min(5, 3, 8, 1))
print(max([10, 20, 15]))

# Sum
print(sum([1, 2, 3, 4, 5]))
print(sum([10, 20, 30], 100))

# Power
print(pow(2, 3))
print(pow(5, 2))

# Square root
print(sqrt(16))
print(sqrt(25))

# Round
print(round(3.14159, 2))
print(round(2.5))


# =============================================================================
# 5. Character Functions
# =============================================================================

# Get ASCII code of character
print(ord("A"))
print(ord("a"))

# Get character from code
print(chr(65))
print(chr(97))


# =============================================================================
# 6. List and Collection Functions
# =============================================================================

# Sorted - sort a list
unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
sorted_asc = sorted(unsorted)
print(sorted_asc)

sorted_desc = sorted(unsorted, True)
print(sorted_desc)

# Reversed - reverse a list
reversed_list = reversed([1, 2, 3, 4, 5])
print(reversed_list)

# Enumerate - get index and value
items = ["apple", "banana", "cherry"]
for pair in enumerate(items):
    print(pair)

# Enumerate with start
for pair in enumerate(items, 1):
    print(pair)

# Zip - combine lists
names = ["Alice", "Bob", "Charlie"]
ages = [25, 30, 35]
combined = zip(names, ages)
for pair in combined:
    print(pair)


# =============================================================================
# 7. Boolean Logic Functions
# =============================================================================

# any() - check if any element is true
print(any([False, False, True]))
print(any([False, False, False]))
print(any([]))

# all() - check if all elements are true
print(all([True, True, True]))
print(all([True, False, True]))
print(all([]))


# =============================================================================
# 8. Type Checking Functions
# =============================================================================

# type() - get type of value
print(type(42))
print(type(3.14))
print(type("hello"))
print(type([1, 2, 3]))
print(type(True))
print(type(None))

# isinstance() - check if value is of type
x = 42
print(isinstance(x, "int"))
print(isinstance(x, "str"))

y = "hello"
print(isinstance(y, "str"))
print(isinstance(y, "int"))


# =============================================================================
# 9. List Creation
# =============================================================================

# Create empty list
empty = list()
print(empty)

# Create list from iterable
string_as_list = list("ABC")
print(string_as_list)

# Create dict
my_dict = dict()
print(my_dict)


# =============================================================================
# 10. Range Function (Already available)
# =============================================================================

# Range with 1 argument
print(range(5))

# Range with 2 arguments
print(range(2, 7))

# Range with step
print(range(0, 10, 2))


# =============================================================================
# 11. Practical Examples
# =============================================================================

# Sum of squares using list and math
numbers = [1, 2, 3, 4, 5]
squares = []
for n in numbers:
    squares.append(pow(n, 2))
total = sum(squares)
print(total)

# Find min and max of list
data = [42, 17, 93, 5, 68]
print(min(data))
print(max(data))
print(sorted(data))

# String operations
text = "hython"
print(len(text))
print(sorted(text))
print(reversed(text))


# =============================================================================
# 12. Advanced Examples
# =============================================================================

# Process list with enumeration
items = ["a", "b", "c", "d"]
for pair in enumerate(items):
    idx = pair[0]
    val = pair[1]
    print(str(idx) + ": " + val)

# Check multiple conditions
values = [10, 0, 20, 30]
if any(values):
    print("At least one value is non-zero")

if not all(values):
    print("Not all values are non-zero")

# Type-based logic
values = [42, "hello", 3.14, True, None]
for v in values:
    t = type(v)
    if t == "int":
        print("Integer: " + str(v))
    elif t == "str":
        print("String: " + v)
    elif t == "float":
        print("Float: " + str(v))


# =============================================================================
# 13. Final Output
# =============================================================================

print("All examples completed successfully!")
