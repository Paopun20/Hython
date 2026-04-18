package paopao.hython;
import paopao.hython.utils.Int8;

class Expr {
	public var expr:ExprDef;
	public var line:Int;
	public var col:Int;

	public function new(expr:ExprDef, line:Int, col:Int) {
		this.expr = expr;
		this.line = line;
		this.col = col;
	}
}

// Variable System (local/global/arg)
enum VariableType {
	VLocal(id:String, varType:TypeHint, variable:Null<Dynamic>);
	VGlobal(id:String, varType:TypeHint, variable:Null<Dynamic>);
	VArg(id:String, varType:TypeHint, variable:Null<Dynamic>);
}

// Assignment
enum abstract AssignOp(Int8) {
	var Assign; // =
	var AddAssign; // +=
	var SubAssign; // -=
	var MulAssign; // *=
	var DivAssign; // /=
}

enum AssignTarget {
	TVar(v:VariableType); // x
	TField(obj:Expr, name:String); // obj.x
	TIndex(obj:Expr, index:Expr); // obj[i]
	TTuple(targets:Array<AssignTarget>); // a, b
}

enum CType {
    CInt;
    CFloat;
    CString;
    CBool;
    CCustom(String);
}

// Operators
enum abstract ExprBinop(Int8) {
	var ADD;
	var SUB;
	var MUL;
	var DIV;
	var MOD;

	var EQ;
	var NEQ;
	var LT;
	var GT;
	var LTE;
	var GTE;

	var AND;
	var OR;
}

enum abstract ExprUnop(Int8) {
	var NEG_BIT; // ~
	var NOT; // !
	var NEG; // -

	var INC; // ++
	var DEC; // --
}

// Function / Arguments
class Argument {
	public var name:VariableType;
	public var opt:Bool;
	public var value:Expr;

	public function new(name:VariableType, opt:Bool = false, ?value:Expr) {
		this.name = name;
		this.opt = opt;
		this.value = value;
	}
}

// Object / Struct-like
class ObjectField {
	public var name:String;
	public var expr:Expr;

	public function new(name:String, expr:Expr) {
		this.name = name;
		this.expr = expr;
	}
}

class ImportItem {
	public var name:String;
	public var asName:VariableType;

	public function new(name:String, asName:VariableType) {
		this.name = name;
		this.asName = asName;
	}
}

enum abstract EImportMode(Int) {
	var INormal;
	var IAll;
}

class SwitchCase {
	public var values:Array<Expr>;
	public var expr:Expr;

	public function new(values:Array<Expr>, expr:Expr) {
		this.values = values;
		this.expr = expr;
	}
}

enum ExprDef {
	// Info (variable table)
	EInfo(varNames:Array<String>);

	// Literals
	EConstInt(value:Int);
	EConstFloat(value:Float);
	EConstString(value:String);
	EConstBool(value:Bool);
	EConstNone;

	// Variables
	EVar(v:VariableType);

	// Assignment
	EAssign(target:AssignTarget, op:AssignOp, expr:Expr);

	// Operators
	EBinop(op:ExprBinop, left:Expr, right:Expr);
	EUnop(op:ExprUnop, expr:Expr);

	// Control Flow
	EIf(cond:Expr, thenExpr:Expr, elseExpr:Expr);
	EWhile(cond:Expr, body:Expr);
	EBlock(exprs:Array<Expr>);

	// Functions
	EFunction(args:Array<Argument>, body:Expr);
	ECall(func:Expr, args:Array<Expr>);
	EReturn(expr:Expr);

	// Objects / Access
	EObject(fields:Array<ObjectField>);
	EField(obj:Expr, name:String);
	EIndex(obj:Expr, index:Expr);

	// Import
	EImport(module:String, asName:VariableType);
	EImportFrom(module:String, names:Array<ImportItem>);

	// AWait / Async
	EAsyncFunction(args:Array<Argument>, body:Expr);
	EAwait(expr:Expr);

	// Switch
	ESwitch(expr:Expr, cases:Array<SwitchCase>, defaultExpr:Expr);
}

enum TypeHint {
	TNumber;
	TString;
	TBool;
	TAny;
	TArray(elementType:TypeHint);
	TDict(keyType:TypeHint, valueType:TypeHint);
	TFunc(params:Array<TypeHint>, returnType:TypeHint);
	TCustom(className:String); // Para clases externas como FlxSound
}

