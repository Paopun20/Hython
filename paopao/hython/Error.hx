package paopao.hython;

import haxe.EnumTools;

enum ErrorDef {
	SyntaxError(msg:String);
	TabError(msg:String);
	IndentationError(msg:String);
	TypeError(msg:String);
	NameError(msg:String);
	IndexError(msg:String);
	KeyError(msg:String);
	AttributeError(msg:String);
	ValueError(msg:String);
	ZeroDivisionError;
	RecursionError(msg:String);
	ImportError(msg:String);
	CustomError(msg:String);
	NotImplementedError(msg:String);
}

class Error {
	public var error:ErrorDef;
	public var line:Int;
	public var col:Int;
	public var filename:String;

	public function new(error:ErrorDef, line:Int, col:Int, ?filename:String) {
		this.error = error;
		this.line = line;
		this.col = col;
		this.filename = filename ?? "<unknown>";
	}

	// Automatically gets enum constructor name.
	public inline function errorName():String {
		return Type.enumConstructor(error);
	}

	private function errorMessage():String {
		return switch (error) {
			case ZeroDivisionError:
				"division by zero";
			default:
				var params = Type.enumParameters(error);

				params.length > 0 ? Std.string(params[0]) : "";
		}
	}

	public function toString():String {
		return '${errorName()}: ${errorMessage()}' + '\n  at line ${line}, col ${col} in ${filename}';
	}
}
