package paopao.hython;

import haxe.Exception;

enum ErrorDef {
    SyntaxError(String);
    TypeError(String);
    NameError(String);
    IndexError(String);
    KeyError(String);
    AttributeError(String);
    ValueError(String);
    ZeroDivisionError;
    ImportError(String);
}

class Error extends Exception {
    public var error:ErrorDef;
    public var line:Int;
    public var col:Int;

    public function new(error:ErrorDef, line:Int, col:Int) {
        super();
        this.error = error;
        this.line = line;
        this.col = col;
    }

    public function toString():String {
        return 'Error at line ${line}, column ${col}: ${error}';
    }
}