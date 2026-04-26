// This file defines the Abstract Syntax Tree (AST) for the Python language (CPython-aligned).
// The AST strictly separates expressions and statements, matching Python's execution model.
// Expressions produce values, while statements control flow and side effects.
// This structure is designed for use in parsing, semantic analysis, and bytecode generation.
package paopao.hython;

import paopao.hython.utils.Int8; // Retained for enum backing types where needed
import haxe.ds.ObjectMap;

typedef SourcePos = {
	var line:Int;
	var col:Int;
	var ?colStart:Int;
	var ?colEnd:Int;
}

// Root Module
// Represents a full Python module (a file).
// Contains a sequence of statements executed top-to-bottom.
class Module {
	public var body:Array<Stmt>;

	public function new(body:Array<Stmt>) {
		this.body = body;
	}
}

// Statement System (Python is statement-based)

enum Stmt {
	// Expression statement (e.g. function calls, standalone expressions)
	SExpr(value:Expr);

	// Assignment: a = 1, a = b = 2
	// targets are expressions (Name, Attribute, Subscript, Tuple, List)
	SAssign(targets:Array<Expr>, value:Expr);

	// Return statement
	SReturn(value:Null<Expr>);

	// Control flow
	SIf(test:Expr, body:Array<Stmt>, orelse:Array<Stmt>);
	SWhile(test:Expr, body:Array<Stmt>, orelse:Array<Stmt>);
	SFor(target:Expr, iter:Expr, body:Array<Stmt>, orelse:Array<Stmt>, isAsync:Bool);

	// Loop control
	SBreak;
	SContinue;
	SPass;

	// Function definition
	SFunctionDef(name:String, args:Arguments, body:Array<Stmt>, returns:Null<Expr>, isAsync:Bool);

	// Class definition
	SClassDef(name:String, bases:Array<Expr>, body:Array<Stmt>);

	// Exception handling
	STry(body:Array<Stmt>, handlers:Array<ExceptHandler>, orelse:Array<Stmt>, finalbody:Array<Stmt>);

	// Imports
	SImport(names:Array<Alias>);
	SImportFrom(module:String, names:Array<Alias>);
}

// Expression System (value-producing nodes)

enum Expr {
	// Variable access (identifier)
	EName(id:String);

	// Constants: int, float, string, bool, None
	EConstant(value:ConstValue);

	// Binary operations: + - * / % etc.
	EBinOp(left:Expr, op:BinOp, right:Expr);

	// Unary operations: not, -, +, ~
	EUnaryOp(op:UnaryOp, operand:Expr);

	// Function calls
	ECall(func:Expr, args:Array<Expr>);

	// Attribute access: obj.field
	EAttribute(value:Expr, attr:String);

	// Indexing: obj[index]
	ESubscript(value:Expr, slice:Expr);

	// Collections
	EList(elts:Array<Expr>);
	ETuple(elts:Array<Expr>);
	EDict(keys:Array<Expr>, values:Array<Expr>);

	// Conditional expression (ternary): a if cond else b
	EIfExp(test:Expr, body:Expr, orelse:Expr);

	// Lambda expression
	ELambda(args:Arguments, body:Expr);

	// Async / generator
	EAwait(value:Expr);
	EYield(value:Null<Expr>);
}

// Operators (Python-native only)

enum abstract BinOp(Int8) {
	var Add; // +
	var Sub; // -
	var Mult; // *
	var Div; // /
	var Mod; // %

	var Eq; // ==
	var NotEq; // !=
	var Lt; // <
	var Gt; // >
	var LtE; // <=
	var GtE; // >=

	var And; // and
	var Or; // or
}

enum abstract UnaryOp(Int8) {
	var Invert; // ~
	var Not; // not
	var UAdd; // +x
	var USub; // -x
}

// Constants

enum ConstValue {
	// Primitive constants
	CInt(value:Int);
	CFloat(value:Float);
	CString(value:String);
	CBool(value:Bool);
	CNone;

	// for hook into Haxe objects (e.g. for representing Python objects in the interpreter)
	VObject(value:Map<String, ConstValue>);
	VFunction(value:(Array<ConstValue>) -> ConstValue);
}

// Function Arguments
// Represents function argument definitions.
// Matches Python's flexible argument system (simplified base version).
class Arguments {
	public var args:Array<Arg>;

	public function new(args:Array<Arg>) {
		this.args = args;
	}
}

// Single argument
class Arg {
	public var name:String;
	public var annotation:Null<Expr>; // Type hint (optional)

	public function new(name:String, annotation:Null<Expr>) {
		this.name = name;
		this.annotation = annotation;
	}
}

// Import System
// import x as y
class Alias {
	public var name:String;
	public var asname:Null<String>;

	public function new(name:String, asname:Null<String>) {
		this.name = name;
		this.asname = asname;
	}
}

// Exception Handling
// except ExceptionType as e:
class ExceptHandler {
	public var type:Null<Expr>; // null = bare except
	public var name:Null<String>;
	public var body:Array<Stmt>;

	public function new(type:Null<Expr>, name:Null<String>, body:Array<Stmt>) {
		this.type = type;
		this.name = name;
		this.body = body;
	}
}

class NodeMeta {
	private static var stmtPositions:ObjectMap<Dynamic, SourcePos> = new ObjectMap();
	private static var exprPositions:ObjectMap<Dynamic, SourcePos> = new ObjectMap();

	public static function setStmtPos(stmt:Stmt, pos:SourcePos):Stmt {
		stmtPositions.set(cast stmt, pos);
		return stmt;
	}

	public static function setExprPos(expr:Expr, pos:SourcePos):Expr {
		exprPositions.set(cast expr, pos);
		return expr;
	}

	public static function getStmtPos(stmt:Stmt):Null<SourcePos> {
		return stmtPositions.get(cast stmt);
	}

	public static function getExprPos(expr:Expr):Null<SourcePos> {
		return exprPositions.get(cast expr);
	}
}
