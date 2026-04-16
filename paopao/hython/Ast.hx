package paopao.hython;

enum Value {
    VInt(Int);
    VFloat(Float);
    VBool(Bool);
    VString(String);
    VObject(Int); // heap ref
    VNone;
}

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

enum VariableType {

}

/**
 * EInfo will ALWAYS be the first expr.
 * It allows us to use a array instead of a map for varaible storage.
 * MUCH much faster (supported in hscript-improved with INT_VARS compilier flag, default only option here)
 * 
 * See VariableType (Int) and VariableInfo (Array<String> to store the names).
 */
enum ExprDef {
    // literals
    EConstInt(value:Int);
    EConstFloat(value:Float);
    EConstString(value:String);
    EConstBool(value:Bool);
    EConstNone;

    // variables
    EVar(v:VariableType);
    EAssign(v:VariableType, expr:Expr);

    // binary / unary
    EBinop(op:ExprBinop, left:Expr, right:Expr);
    EUnop(op:ExprUnop, expr:Expr);

    // control flow
    EIf(cond:Expr, thenExpr:Expr, elseExpr:Expr);
    EWhile(cond:Expr, body:Expr);

    // blocks
    EBlock(exprs:Array<Expr>);

    // functions
    EFunction(args:Array<Argument>, body:Expr);
    ECall(func:Expr, args:Array<Expr>);
    EReturn(expr:Expr);

    // objects (future)
    EObject(fields:Array<ObjectField>);
    EField(obj:Expr, name:String);
}

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

class SwitchCase {
    public var values:Array<Expr>;
    public var expr:Expr;

    public function new(values:Array<Expr>, expr:Expr) {
        this.values = values;
        this.expr = expr;
    }
}

class ObjectField {
    public var name:String; 
    public var expr:Expr;

    public function new(name:String, expr:Expr) {
        this.name = name;
        this.expr = expr;
    }
}

enum abstract ExprBinop(Int) {

}

/**
 * Derived from haxe manual:
 * https://haxe.org/manual/expression-operators-unops.html
 */
enum abstract ExprUnop(Int) {
    var NEG_BIT:ExprUnop; // ~

    var NOT:ExprUnop; // !
    var NEG:ExprUnop; // -

    var INC:ExprUnop; // ++
    var DEC:ExprUnop; // --
}

enum EImportMode {
}