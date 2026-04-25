package paopao.hython;

// Error handling for the interpreter. This is used for both compile-time and runtime errors.
enum ErrorDef {
	SyntaxError(String:String);
	TabError(String:String);
	IndentationError(String:String);
	TypeError(String:String);
	NameError(String:String);
	IndexError(String:String);
	KeyError(String:String);
	AttributeError(String:String);
	ValueError(String:String);
	ZeroDivisionError;
	ImportError(String:String);
}

// Column range for the source-snippet indicator rendered by Traceback.
//
// All columns are 1-based and inclusive.
//
// When opStart / opEnd are set the indicator uses the CPython 3.11+ style:
//
//     10 * (1/0)
//           ~^~
//
// where `~` marks the operands and `^` marks the operator.
// When they are null the entire range is underlined with `^`:
//
//     undefined_var + 1
//     ^^^^^^^^^^^^^
typedef Span = {
	var colStart:Int; // first column of the highlighted region
	var colEnd:Int; // last column of the highlighted region (inclusive)
	var ?opStart:Int; // first column of the operator   (null → all-^ style)
	var ?opEnd:Int; // last  column of the operator   (null → all-^ style)
}

// Exception class for errors in the interpreter.
// Carries the error kind, source location, an optional column-level Span
// for rich indicator rendering, and a call-stack of scope names.
class Error {
	public var error:ErrorDef;
	public var line:Int;
	public var col:Int;
	public var filename:String; // e.g. "<module>", "<python-input-0>", "main.py"
	public var span:Null<Span>; // column range for the ~^~ indicator (optional)
	public var stack:Array<String>; // function names (innermost last)

	public function new(error:ErrorDef, line:Int, col:Int, ?filename:String, ?span:Null<Span>, ?stack:Array<String>) {
		this.error = error;
		this.line = line;
		this.col = col;
		this.filename = filename != null ? filename : "<unknown>";
		this.span = span;
		this.stack = stack != null ? stack : [];
	}

	// CPython-style error class name (no spaces).
	public function errorName():String {
		return switch (error) {
			case SyntaxError(_): "SyntaxError";
			case TabError(_): "TabError";
			case IndentationError(_): "IndentationError";
			case TypeError(_): "TypeError";
			case NameError(_): "NameError";
			case IndexError(_): "IndexError";
			case KeyError(_): "KeyError";
			case AttributeError(_): "AttributeError";
			case ValueError(_): "ValueError";
			case ZeroDivisionError: "ZeroDivisionError";
			case ImportError(_): "ImportError";
		}
	}

	public function errorMessage():String {
		return switch (error) {
			case SyntaxError(msg): msg;
			case TabError(msg): msg;
			case IndentationError(msg): msg;
			case TypeError(msg): msg;
			case NameError(msg): msg;
			case IndexError(msg): msg;
			case KeyError(msg): msg;
			case AttributeError(msg): msg;
			case ValueError(msg): msg;
			case ZeroDivisionError: "division by zero";
			case ImportError(msg): msg;
		}
	}

	// Plain one-liner fallback (use Traceback.format() for the full CPython look).
	public function toString():String {
		var s = errorName() + ": " + errorMessage();
		s += '\n  at line ${line}, col ${col} in ${filename}';
		for (frame in stack)
			s += '\n  in ' + frame;
		return s;
	}
}
