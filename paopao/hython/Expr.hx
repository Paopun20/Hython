package paopao.hython;

enum Const {
	CInt(v:Int);
	CFloat(f:Float);
	CString(s:String);
}

typedef PositionInfo = {
	var pmin:Int;
	var pmax:Int;
	var origin:String;
	var line:Int;
}

typedef ExprDef = Expr;

enum Expr {
	EConst(c:Const);
	EIdent(v:String);
	EVar(n:String, ?t:CType, ?e:Expr);
	EParent(e:Expr);
	EBlock(e:Array<Expr>);
	EField(e:Expr, f:String);
	EBinop(op:String, e1:Expr, e2:Expr);
	EUnop(op:String, prefix:Bool, e:Expr);
	ECall(e:Expr, params:Array<Expr>);
	EIf(cond:Expr, e1:Expr, ?e2:Expr);
	EWhile(cond:Expr, e:Expr);
	EFor(v:String, it:Expr, e:Expr);
	EBreak();
	EContinue();
	EFunction(args:Array<Argument>, e:Expr, ?name:String, ?ret:CType);
	EReturn(?e:Expr);
	EArray(e:Expr, index:Expr);
	EArrayDecl(e:Array<Expr>);
	ENew(cl:String, params:Array<Expr>);
	EThrow(e:Expr);
	ETry(e:Expr, v:String, t:Null<CType>, ecatch:Expr);
	EObject(fl:Array<{name:String, e:Expr}>);
	ETernary(cond:Expr, e1:Expr, e2:Expr);
	ESwitch(e:Expr, cases:Array<{values:Array<Expr>, expr:Expr}>, ?defaultExpr:Expr);
	// EDoWhile( cond : Expr, e : Expr);
	// EMeta( name : String, args : Array<Expr>, e : Expr );
	ECheckType(e:Expr, t:CType);
	EForGen(it:Expr, e:Expr);
	EImport(path:Array<String>, ?alias:String);
	EImportFrom(path:Array<String>, items:Array<String>, ?alias:String);
	EDel(e:Expr);
	EAssert(cond:Expr, ?msg:Expr);
	EComprehension(expr:Expr, loops:Array<{varname:String, iter:Expr, ?cond:Expr}>, isDict:Bool, key:Null<Expr>);
	EGenerator(expr:Expr, loops:Array<{varname:String, iter:Expr, ?cond:Expr}>);
	ESlice(e:Expr, start:Expr, end:Expr, step:Expr);
	ETuple(elements:Array<Expr>);
	EClass(name:String, baseClasses:Array<Expr>, body:Expr);
	ERoot(?e:Expr, ?pos:PositionInfo);
}

typedef Argument = {name:String, ?t:CType, ?opt:Bool, ?value:Expr, ?isVarArgs:Bool, ?isKwArgs:Bool};
typedef Metadata = Array<{name:String, params:Array<Expr>}>;

enum CType {
	CTPath(path:Array<String>, ?params:Array<CType>);
	CTFun(args:Array<CType>, ret:CType);
	CTAnon(fields:Array<{name:String, t:CType, ?meta:Metadata}>);
	CTParent(t:CType);
	CTOpt(t:CType);
	CTNamed(n:String, t:CType);
	CTExpr(e:Expr); // for type parameters only
}

enum Error {
	EInvalidChar(c:Int);
	EUnexpected(s:String);
	EUnterminatedString;
	EUnterminatedComment;
	EInvalidPreprocessor(msg:String);
	EUnknownVariable(v:String);
	EInvalidIterator(v:String);
	EInvalidOp(op:String);
	EInvalidAccess(f:String);
	ECustom(msg:String);
	ETypeError(msg:String);
	EValueError(msg:String);
	ETabError(msg:String);
	EZeroDivisionError(msg:String);
	EExitException(code:Int);
	ERecursionError(msg:String);
	EAssertionError(msg:String);
	ENameError(msg:String);
	EKeyError(msg:String);
	EClassNotAllowed(msg:String);
	ESyntaxError(msg:String);
}

enum ModuleDecl {
	DPackage(path:Array<String>);
	DImport(path:Array<String>, ?everything:Bool);
	DClass(c:ClassDecl);
	DTypedef(c:TypeDecl);
}

typedef ModuleType = {
	var name:String;
	var params:{}; // TODO : not yet parsed
	var meta:Metadata;
	var isPrivate:Bool;
}

typedef ClassDecl = {
	> ModuleType,
	var extend:Null<CType>;
	var implement:Array<CType>;
	var fields:Array<FieldDecl>;
	var isExtern:Bool;
}

typedef TypeDecl = {
	> ModuleType,
	var t:CType;
}

typedef FieldDecl = {
	var name:String;
	var meta:Metadata;
	var kind:FieldKind;
	var access:Array<FieldAccess>;
}

enum FieldAccess {
	APublic;
	APrivate;
	AInline;
	AOverride;
	AStatic;
	AMacro;
}

enum FieldKind {
	KFunction(f:FunctionDecl);
	KVar(v:VarDecl);
}

typedef FunctionDecl = {
	var args:Array<Argument>;
	var expr:Expr;
	var ret:Null<CType>;
}

typedef VarDecl = {
	var get:Null<String>;
	var set:Null<String>;
	var expr:Null<Expr>;
	var type:Null<CType>;
}
