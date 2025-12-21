# Hython Architecture

Understanding how Hython works under the hood.

## Table of Contents

- [Overview](#overview)
- [Core Components](#core-components)
- [Execution Pipeline](#execution-pipeline)
- [Memory Model](#memory-model)
- [Design Decisions](#design-decisions)

## Overview

Hython is designed as a lightweight, embeddable interpreter that bridges Python syntax with Haxe's type system and runtime. The architecture prioritizes:

- **Simplicity** – Easy to understand and maintain
- **Embedability** – Seamless integration with Haxe
- **Safety** – Sandboxable execution environment
- **Performance** – Minimal overhead for script execution

### High-Level Architecture

```
┌─────────────────────────────────────┐
│      Hython Source Code             │
│    (Python-style syntax)            │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│       Lexer / Tokenizer             │
│    (Source → Token Stream)          │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│       Parser                        │
│    (Token Stream → AST)             │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│       Interpreter                   │
│    (AST → Execution)                │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│       Result                        │
│    (Dynamic values)                 │
└─────────────────────────────────────┘
```

---

## Core Components

### Lexer (`Lexer.hx`)

The lexer tokenizes Hython source code into a stream of tokens.

**Responsibilities:**
- Recognize Python keywords (`if`, `else`, `for`, `while`, `def`, etc.)
- Identify operators (`+`, `-`, `*`, `/`, `==`, etc.)
- Track indentation levels (significant in Python)
- Extract literals (numbers, strings)
- Manage comments

**Key Features:**
- Indentation-based block detection
- String literal handling (with f-strings)
- Number parsing (integers and floats)

**Output:** Token stream

### Parser (`Parser.hx`)

The parser converts tokens into an Abstract Syntax Tree (AST).

**Responsibilities:**
- Validate syntax
- Build expression trees
- Handle operator precedence
- Construct control flow structures
- Process function definitions

**Key Features:**
- Recursive descent parsing
- Expression parsing with precedence
- Block handling via indentation
- Function definition parsing

**Output:** AST (expression tree)

### Interpreter (`Interp.hx`)

The interpreter executes the AST.

**Responsibilities:**
- Maintain variable scope
- Evaluate expressions
- Execute statements
- Manage function calls and returns
- Handle control flow (if, for, while, break, continue)

**Key Features:**
- Dynamic variable storage
- Scope management (function scopes)
- Built-in function support
- Expression evaluation

**Output:** Dynamic values

### Expression Representation (`Expr.hx`)

Defines the AST node types.

**Node Types:**
- `EConst(value)` – Constants (numbers, strings, booleans)
- `EVar(name)` – Variable references
- `EBinop(op, e1, e2)` – Binary operations
- `ECall(func, args)` – Function calls
- `EList(items)` – List literals
- `EDict(pairs)` – Dictionary literals
- `EIf(cond, then, else)` – Conditional expressions
- `EFor(var, iter, body)` – For loops
- `EWhile(cond, body)` – While loops
- `EFunction(params, body)` – Function definitions
- `EBlock(exprs)` – Statement blocks
- And more...

### Python Integration (`PythonExecutor.hx`)

Handles execution of actual Python code.

**Features:**
- Detects Python availability
- Spawns Python processes
- Captures output and errors
- Provides command-line arguments

---

## Execution Pipeline

### Step 1: Lexical Analysis

```
Input: 'x = 10\nif x > 5:\n    print("yes")'

Lexer Output:
[ID("x"), OP("="), NUM(10), 
 KW("if"), ID("x"), OP(">"), NUM(5), OP(":"), INDENT,
 ID("print"), OP("("), STR("yes"), OP(")"), DEDENT]
```

### Step 2: Parsing

```
Parser Input: Token stream

Parser Output (AST):
EBlock([
  EBinop(Assign, EVar("x"), EConst(10)),
  EIf(
    EBinop(Gt, EVar("x"), EConst(5)),
    ECall(EVar("print"), [EConst("yes")])
  )
])
```

### Step 3: Interpretation

```
Interpreter Input: AST

Execution:
1. Create scope
2. Evaluate EBinop (x = 10) → set x to 10
3. Evaluate EIf condition (x > 5) → true
4. Execute if body → call print("yes")

Output: "yes"
```

---

## Memory Model

### Variable Scope

Hython uses a **scope chain** for variable lookup:

```
Global Scope
    │
    ├─ x = 10
    ├─ y = 20
    │
    └─ Function Scope (greet)
           │
           ├─ name = "Alice"
           ├─ message = "Hello, Alice"
           │
           └─ Local variables
```

### Variable Lookup

When a variable is referenced:

1. Check local scope
2. Check parent scopes (up the chain)
3. Check global scope
4. Return error if not found

### Memory Management

- Variables stored in `Map<String, Dynamic>`
- Garbage collection handled by Haxe runtime
- No explicit memory management needed

---

## Design Decisions

### Why Dynamic Typing?

Hython uses dynamic typing to:
- Simplify the interpreter
- Provide Python-like flexibility
- Reduce compile-time complexity

Tradeoff: Less type safety, more runtime checks.

### Why Not Full Python Compatibility?

Hython is a **subset** of Python to:
- Keep implementation lightweight
- Avoid huge dependencies
- Focus on common use cases
- Ensure sandboxability

Complex Python features (decorators, generators, classes, imports) are not implemented.

### Indentation-Based Blocks

Hython respects Python's indentation syntax:
- **Advantage:** Familiar to Python developers
- **Advantage:** Enforces readable code
- **Challenge:** Lexer must track whitespace carefully

### Embeddability

Hython is designed to be embedded:
- Single `Interp` class for execution
- Variables accessible via `get()` / `set()`
- Results returned as `Dynamic`
- No global state (except per interpreter)

---

## Performance Characteristics

### Execution Speed

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| Variable lookup | O(depth) | Depends on scope depth |
| Function call | O(1) | + body execution time |
| List access | O(1) | Direct array indexing |
| Dictionary access | O(1) | Hash map lookup |
| List append | O(1) amortized | Dynamic array growth |

### Memory Usage

- **Scope storage:** O(variables)
- **AST size:** O(code length)
- **Function storage:** O(functions)

---

## Extension Points

### Adding Built-in Functions

To add new built-in functions, modify the interpreter's built-in function lookup.

### Custom Data Types

Haxe objects can be stored as `Dynamic` and accessed from Hython:

```haxe
var myObject = new MyClass();
interp.set("myObj", myObject);
interp.execute('
print(myObj.property)
myObj.method()
');
```

### String Formatting

F-strings are parsed specially to support Python-like string interpolation:

```python
name = "World"
message = f"Hello, {name}!"
```

---

## Limitations

### Not Supported

- Classes and OOP
- Decorators
- Generators and iterators
- Context managers (with statement)
- Exception handling (try/except)
- Module imports (limited)
- Async/await

### Performance Limitations

- No JIT compilation
- Interpreted execution (not compiled)
- Dynamic dispatch overhead
- Suitable for moderate-complexity scripts

---

## Future Improvements

Potential enhancements:

- [ ] Class support
- [ ] Better error messages with line numbers
- [ ] Performance optimizations
- [ ] More built-in functions
- [ ] Standard library expansion
- [ ] Compilation to bytecode

---

## Contributing

Understanding the architecture helps when contributing:

1. **Bug fixes:** Identify which component needs fixing
2. **Features:** Consider impact on all components
3. **Performance:** Profile before and after changes
4. **Testing:** Ensure changes don't break existing functionality

---

For implementation details, see the source files in `hython/`:
- `Lexer.hx` – Tokenization
- `Parser.hx` – AST construction
- `Interp.hx` – Execution
- `Expr.hx` – AST definitions
- `PythonExecutor.hx` – Python integration

Ready to dive deeper? Check out the source code!
