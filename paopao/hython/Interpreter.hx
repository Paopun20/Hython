package paopao.hython;

import haxe.Constraints;
import haxe.PosInfos;
import haxe.ds.StringMap;
import paopao.hython.utils.UnsafeReflect as Reflect;
import paopao.hython.Semantic;
import paopao.hython.Ast;
import paopao.hython.Error;
import paopao.hython.PyData;
import haxe.exceptions.NotImplementedException;

using thx.Arrays;

// Simple Interpreter AST Walker
@:nullSafety(Strict)
class Interpreter {
	public var filename(get, null):String;
	var _filename = "";
	inline function get_filename()
		return _filename;

	var globals: StringMap<PyValue>;

	public static var maxCallDepth = 1000;

	public function new(filename:String) {
		this._filename = filename;
		this.globals = new StringMap<PyValue>();
	}

	/*
		find in root or class
	*/
	private function findMethods(body: Stmt, name:String): Null<Stmt> {
		throw new NotImplementedException();
	}

	private function runBody(body: Stmt, args:Null<Array<PyValue>>) {
		var isRootMode = args == null;
		
	}

	public function callDef(funcName:String, args:Array<PyValue>): PyValue {
		throw new NotImplementedException();
	}

	public function run(source:String, ?skipChacking:Bool = false) {
		var code:Module = Interpreter.compile(source, filename, skipChacking);
	}

	

	/**
	 * Instantiates a script class and calls its constructor with the given args.
	 * args are Haxe-side values — they'll be converted to script Values automatically.
	 */
	public function instantiate(name:String, args:Array<Dynamic>):Class<Dynamic> {
		throw new NotImplementedException();
	}

	public static function compile(source:String, ?filename:String, ?skipChacking:Bool = false):Module {
		var lexer = new Lexer(source);
		var ast = lexer.tokenize();

		var code = new Parser(ast, lexer.tokenPositions).parse();

		if (!skipChacking)
			Semantic.analyze(code, filename != null ? filename : "<inline>");

		return code;
	}
}
