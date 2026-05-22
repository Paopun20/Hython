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
	RecursionError(String:String);
	ImportError(String:String);
	CustomError(String:String); // for internal use when we just want to throw a message without a specific error type
}

class Error {
	public var error:ErrorDef;
	public var line:Int;
	public var col:Int;
	public var filename:String; // e.g. "<module>", "<python-input-0>", "main.py"

	public function new(error:ErrorDef, line:Int, col:Int, ?filename:String) {
		this.error = error;
		this.line = line;
		this.col = col;
		this.filename = filename != null ? filename : "<unknown>";
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
			case RecursionError(_): "RecursionError";
			case ImportError(_): "ImportError";
			case CustomError(_): "CustomError";
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
			case RecursionError(msg): msg;
			case ImportError(msg): msg;
			case CustomError(msg): msg;
		}
	}

	// Plain one-liner fallback (use Traceback.format() for the full CPython look).
	public function toString():String {
		var s = errorName() + ": " + errorMessage();
		s += '\n  at line ${line}, col ${col} in ${filename}';
		return s;
	}
}
