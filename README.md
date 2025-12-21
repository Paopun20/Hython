# Hython Interpreter

Hython is a Python-inspired scripting interpreter written in Haxe that brings Python-style syntax to the Haxe ecosystem.

It provides a dynamic, embeddable scripting runtime with Python-like semantics,
designed for use in Haxe projects such as games, tools, and modding environments
(e.g. Friday Night Funkin' Psych Engine forks).

Hython is **not a full Python implementation**. Instead, it focuses on:
- **Python-style syntax** with colons and indentation-based blocks
- Dynamic typing and expressions
- Functions and closures
- Control flow (if, elif, else, for, while, break, continue, return)
- List and dictionary literals
- Lambda expressions
- Safe embedding and sandbox-friendly design

This makes Hython suitable as a lightweight, familiar scripting language for Python developers
while maintaining full compatibility with Haxe's powerful type system and standard library.

## Usage

To use Hython in your Haxe project, add the following dependency to your `build.hxml` file:

```
-lib hython
```

Then, you can import and use the Hython interpreter in your code:

```haxe
import hython.Parser;
import hython.Interp;

class Main {
	static function main() {
		var code = "print('Hello, Hython!')";
		var p = new Parser();
		var expr = p.parseString(code);
		new Interp().execute(expr);
	}
}
```