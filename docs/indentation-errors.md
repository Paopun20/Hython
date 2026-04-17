# Python Indentation Error Support in Hython

## Overview
Hython now properly detects and reports Python's indentation errors, specifically:
- **TabError**: Inconsistent use of tabs and spaces
- **IndentationError**: Unindent does not match any outer indentation level (planned)

## TabError Implementation

### Detection
The Hython Lexer tracks indentation style from the first indented line:
- If spaces are detected, the file must use spaces for all indentation
- If tabs are detected, the file must use tabs for all indentation
- Mixing tabs and spaces on the same line triggers a **TabError**

### Error Format
```
TabError: inconsistent use of tabs and spaces in indentation
  at line 3, col 1
```

### Example 1: Mixed Tabs and Spaces
```python
def greet(name):
    print(f"Hello, {name}!")  # 4 spaces
	print("Welcome to Real Python!")  # 1 tab

greet("Ada")
```

**Error Output:**
```
TabError: inconsistent use of tabs and spaces in indentation
  at line 3, col 1
```

This matches Python's behavior:
```
File "/path/to/mix.py", line 3
    print("Welcome to Real Python!")  # 1 tab
^
TabError: inconsistent use of tabs and spaces in indentation
```

## Valid Indentation

### Consistent Spaces (Recommended)
```python
def calculate_area(radius):
    area = 3.14 * radius ** 2
    return area
```
✓ All lines use 4 spaces for indentation

### Consistent Tabs
```python
def greet(name):
	if name:
		print("Hello, " + name)
```
✓ All lines use tabs for indentation

## Implementation Details

### Lexer Changes
1. Added `indentationStyle` field to track whether file uses "spaces" or "tabs"
2. Added `validateLineIndentation()` method to check for mixed tabs/spaces
3. Modified `nextToken()` to validate indentation at line start (col == 1)

### Error Enum
Added to `Error.hx`:
- `TabError(String:String)` - for mixed tabs and spaces
- `IndentationError(String:String)` - reserved for future use

### Code Example
```haxe
private function validateLineIndentation(indentChars:String):Void {
    if (indentChars.length > 0) {
        var hasSpaces = indentChars.indexOf(" ") >= 0;
        var hasTabs = indentChars.indexOf("\t") >= 0;
        
        if (hasSpaces && hasTabs) {
            throw new Error(TabError("inconsistent use of tabs and spaces in indentation"), line, col);
        }
        
        if (indentationStyle == null && indentChars.length > 0) {
            indentationStyle = hasSpaces ? "spaces" : "tabs";
        }
        else if (indentationStyle != null) {
            var currentStyle = hasSpaces ? "spaces" : "tabs";
            if (indentationStyle != currentStyle) {
                throw new Error(TabError("inconsistent use of tabs and spaces in indentation"), line, col);
            }
        }
    }
}
```

## Test Coverage
All 65 existing tests continue to pass with the new indentation validation:
- 6 Lexer tests
- 16 Parser tests
- 43 Interpreter tests

## Future: IndentationError
The `IndentationError` variant is reserved for detecting when unindent does not match any outer indentation level:

```python
def calculate_area(radius):
    area = 3.14 * radius ** 2
   return area  # Wrong indentation level!
```

This would trigger: `IndentationError: unindent does not match any outer indentation level`

## References
- Python TabError: https://docs.python.org/3/library/exceptions.html#TabError
- Python IndentationError: https://docs.python.org/3/library/exceptions.html#IndentationError
