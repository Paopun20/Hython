package hython;

import hscript.Expr as HScriptExpr;
import hython.Expr;

class Parser {
	private var parser:hscript.Parser;

	public function new() {
		parser = new hscript.Parser();
	}

	public function parseString(input:String):Expr {
		var hscriptExpr = parser.parseString(input);
		return cast hscriptExpr;
	}
}
