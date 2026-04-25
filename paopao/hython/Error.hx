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

// Exception class for errors in the interpreter. This includes the error type, line and column information, and an optional stack trace.
class Error {
	public var error:ErrorDef;
	public var line:Int;
	public var col:Int;
	public var stack:Array<String>; // function names

	public function new(error:ErrorDef, line:Int, col:Int, ?stack:Array<String>) {
		this.error = error;
		this.line = line;
		this.col = col;
		this.stack = stack != null ? stack : [];
	}

	public function errorName():String {
		switch (error) {
			case SyntaxError(_): return "Syntax Error";
			case TabError(_): return "TabError";
			case IndentationError(_): return "IndentationError";
			case TypeError(_): return "Type Error";
			case NameError(_): return "Name Error";
			case IndexError(_): return "Index Error";
			case KeyError(_): return "Key Error";
			case AttributeError(_): return "Attribute Error";
			case ValueError(_): return "Value Error";
			case ZeroDivisionError: return "Zero Division Error";
			case ImportError(_): return "Import Error";
		}
	}

	public function errorMessage():String {
		switch (error) {
			case SyntaxError(msg): return msg;
			case TabError(msg): return msg;
			case IndentationError(msg): return msg;
			case TypeError(msg): return msg;
			case NameError(msg): return msg;
			case IndexError(msg): return msg;
			case KeyError(msg): return msg;
			case AttributeError(msg): return msg;
			case ValueError(msg): return msg;
			case ZeroDivisionError: return "Division by zero";
			case ImportError(msg): return msg;
		}
	}

	public function toString():String {
		var s = errorName() + ": " + errorMessage();
		s += '\n  at line ${line}, col ${col}';

		for (frame in stack) {
			s += '\n  in ' + frame;
		}

		return s;
	}
}
