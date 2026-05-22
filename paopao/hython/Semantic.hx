package paopao.hython;

import paopao.hython.Ast;
import paopao.hython.Error;
import paopao.hython.PyData.PyScope;

// Semantic Analyzer
@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class Semantic {
	private static final DEFAULT_PREDEFINED_NAMES:Array<String> = ["len", "print", "range", "type", "int", "str", "bool", "list", "tuple", "dict"];

	private static var currentScope:PyScope;
	private static var inLoop:Int = 0;
	private static var inFunction:Int = 0;
	private static var filename:String = "<unknown>";

	// Entry
	public static function analyze(module:Module, ?filename:String, ?predefinedNames:Array<String>):Void {
		Semantic.filename = filename != null ? filename : "<unknown>";
		Semantic.inLoop = 0;
		Semantic.inFunction = 0;
		currentScope = new PyScope(null);

		for (name in DEFAULT_PREDEFINED_NAMES) {
			currentScope.define(name);
		}
		if (predefinedNames != null) {
			for (name in predefinedNames) {
				currentScope.define(name);
			}
		}

		for (stmt in module.body) {
			visitStmt(stmt);
		}
	}

	// Statement Visitor

	private static function visitStmt(stmt:Stmt):Void {
		switch (stmt) {
			case SExpr(expr):
				visitExpr(expr);

			case SAssign(targets, value):
				visitExpr(value);
				for (t in targets) {
					handleAssignTarget(t);
				}

			case SReturn(value):
				if (inFunction == 0) {
					semanticError(stmt, SyntaxError("return outside function"));
				}
				if (value != null)
					visitExpr(value);

			case SIf(test, body, orelse):
				visitExpr(test);
				visitBlock(body);
				visitBlock(orelse);

			case SWhile(test, body, _):
				visitExpr(test);
				inLoop++;
				visitBlock(body);
				inLoop--;

			case SFor(target, iter, body, _, _):
				visitExpr(iter);
				inLoop++;
				handleAssignTarget(target);
				visitBlock(body);
				inLoop--;

			case SBreak:
				if (inLoop == 0) {
					semanticError(stmt, SyntaxError("break outside loop"));
				}

			case SContinue:
				if (inLoop == 0) {
					semanticError(stmt, SyntaxError("continue outside loop"));
				}

			case SFunctionDef(name, args, body, _, _):
				currentScope.define(name);

				var prev = currentScope;
				currentScope = new PyScope(prev);

				inFunction++;

				for (arg in args.args) {
					currentScope.define(arg.name);
				}

				visitBlock(body);

				inFunction--;
				currentScope = prev;

			case SClassDef(name, bases, body):
				currentScope.define(name);

				var prev = currentScope;
				currentScope = new PyScope(prev);

				for (b in bases)
					visitExpr(b);
				visitBlock(body);

				currentScope = prev;

			case STry(body, handlers, orelse, finalbody):
				visitBlock(body);

				for (h in handlers) {
					if (h.type != null)
						visitExpr(h.type);

					var prev = currentScope;
					currentScope = new PyScope(prev);

					if (h.name != null)
						currentScope.define(h.name);

					visitBlock(h.body);
					currentScope = prev;
				}

				visitBlock(orelse);
				visitBlock(finalbody);

			case SImport(names):
				for (n in names) {
					currentScope.define(n.asname != null ? n.asname : n.name);
				}

			case SImportFrom(_, names):
				for (n in names) {
					currentScope.define(n.asname != null ? n.asname : n.name);
				}

			case SPass:
				// do nothing
		}
	}

	private static function visitBlock(body:Array<Stmt>):Void {
		for (stmt in body) {
			visitStmt(stmt);
		}
	}

	// Expression Visitor

	private static function visitExpr(expr:Expr):Void {
		switch (expr) {
			case EName(name):
				if (!currentScope.exists(name)) {
					semanticError(expr, SyntaxError("undefined variable: " + name));
				}

			case EConstant(_):
				// ok

			case EBinOp(left, _, right):
				visitExpr(left);
				visitExpr(right);

			case EUnaryOp(_, operand):
				visitExpr(operand);

			case ECall(func, args):
				visitExpr(func);
				for (a in args)
					visitExpr(a);

			case EAttribute(value, _):
				visitExpr(value);

			case ESubscript(value, slice):
				visitExpr(value);
				visitExpr(slice);

			case EList(elts):
				for (e in elts)
					visitExpr(e);

			case ETuple(elts):
				for (e in elts)
					visitExpr(e);

			case EDict(keys, values):
				for (k in keys)
					visitExpr(k);
				for (v in values)
					visitExpr(v);

			case EIfExp(test, body, orelse):
				visitExpr(test);
				visitExpr(body);
				visitExpr(orelse);

			case ELambda(args, body):
				var prev = currentScope;
				currentScope = new PyScope(prev);

				for (arg in args.args) {
					currentScope.define(arg.name);
				}

				visitExpr(body);
				currentScope = prev;

			case EAwait(value):
				visitExpr(value);

			case EYield(value):
				if (value != null)
					visitExpr(value);
		}
	}

	// Assignment Handling

	private static function handleAssignTarget(expr:Expr):Void {
		switch (expr) {
			case EName(name):
				currentScope.define(name);

			case ETuple(elts):
				for (e in elts)
					handleAssignTarget(e);

			case EList(elts):
				for (e in elts)
					handleAssignTarget(e);

			case EAttribute(value, _):
				visitExpr(value);

			case ESubscript(value, slice):
				visitExpr(value);
				visitExpr(slice);

			default:
				semanticError(expr, SyntaxError("invalid assignment target"));
		}
	}

	private static function semanticError(node:Dynamic, errorDef:ErrorDef):Void {
		var pos = extractNodePos(node);
		throw new Error(errorDef, pos.line, pos.col, filename);
	}

	private static function extractNodePos(node:Dynamic):SourcePos {
		var stmtPos = NodeMeta.getStmtPos(cast node);
		if (stmtPos != null)
			return stmtPos;

		var exprPos = NodeMeta.getExprPos(cast node);
		if (exprPos != null)
			return exprPos;

		return {
			line: 0,
			col: 0,
			colStart: 0,
			colEnd: 0
		};
	}
}
