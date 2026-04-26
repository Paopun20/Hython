package paopao.hython;

import paopao.hython.Ast;
import paopao.hython.Error;

// Scope System

class Scope {
	public var parent:Scope;
	public var locals:Map<String, Bool>;

	public function new(parent:Scope) {
		this.parent = parent;
		this.locals = new Map();
	}

	public function define(name:String) {
		locals.set(name, true);
	}

	public function exists(name:String):Bool {
		if (locals.exists(name)) return true;
		if (parent != null) return parent.exists(name);
		return false;
	}
}

// Semantic Analyzer

class Semantic {
	private var currentScope:Scope;
	private var inLoop:Int = 0;
	private var inFunction:Int = 0;
	private var filename:String = "<unknown>";

	public function new() {}

	// Entry
	public function analyze(module:Module, ?filename:String):Void {
		this.filename = filename != null ? filename : "<unknown>";
		currentScope = new Scope(null);

		for (stmt in module.body) {
			visitStmt(stmt);
		}
	}

	// Statement Visitor

	private function visitStmt(stmt:Stmt):Void {
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
				if (value != null) visitExpr(value);

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
				// define function name in current scope
				currentScope.define(name);

				// enter new scope
				var prev = currentScope;
				currentScope = new Scope(prev);

				inFunction++;

				// define arguments
				for (arg in args.args) {
					currentScope.define(arg.name);
				}

				visitBlock(body);

				inFunction--;

				currentScope = prev;

			case SClassDef(name, bases, body):
				currentScope.define(name);

				var prev = currentScope;
				currentScope = new Scope(prev);

				for (b in bases) visitExpr(b);
				visitBlock(body);

				currentScope = prev;

			case STry(body, handlers, orelse, finalbody):
				visitBlock(body);

				for (h in handlers) {
					if (h.type != null) visitExpr(h.type);

					var prev = currentScope;
					currentScope = new Scope(prev);

					if (h.name != null) currentScope.define(h.name);

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

	private function visitBlock(body:Array<Stmt>):Void {
		for (stmt in body) {
			visitStmt(stmt);
		}
	}

	// Expression Visitor

	private function visitExpr(expr:Expr):Void {
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
				for (a in args) visitExpr(a);

			case EAttribute(value, _):
				visitExpr(value);

			case ESubscript(value, slice):
				visitExpr(value);
				visitExpr(slice);

			case EList(elts):
				for (e in elts) visitExpr(e);

			case ETuple(elts):
				for (e in elts) visitExpr(e);

			case EDict(keys, values):
				for (k in keys) visitExpr(k);
				for (v in values) visitExpr(v);

			case EIfExp(test, body, orelse):
				visitExpr(test);
				visitExpr(body);
				visitExpr(orelse);

			case ELambda(args, body):
				var prev = currentScope;
				currentScope = new Scope(prev);

				for (arg in args.args) {
					currentScope.define(arg.name);
				}

				visitExpr(body);
				currentScope = prev;

			case EAwait(value):
				visitExpr(value);

			case EYield(value):
				if (value != null) visitExpr(value);
		}
	}

	// Assignment Handling

	private function handleAssignTarget(expr:Expr):Void {
		switch (expr) {

			case EName(name):
				currentScope.define(name);

			case ETuple(elts):
				for (e in elts) handleAssignTarget(e);

			case EList(elts):
				for (e in elts) handleAssignTarget(e);

			case EAttribute(value, _):
				visitExpr(value);

			case ESubscript(value, slice):
				visitExpr(value);
				visitExpr(slice);

			default:
				semanticError(expr, SyntaxError("invalid assignment target"));
		}
	}

	private function semanticError(node:Dynamic, errorDef:ErrorDef):Void {
		var pos = extractNodePos(node);
		var span:Null<Span> = null;
		if (pos.colStart != null && pos.colEnd != null) {
			span = {colStart: pos.colStart, colEnd: pos.colEnd};
		}
		throw new Error(errorDef, pos.line, pos.col, filename, span);
	}

	private function extractNodePos(node:Dynamic):SourcePos {
		var stmtPos = NodeMeta.getStmtPos(cast node);
		if (stmtPos != null) return stmtPos;

		var exprPos = NodeMeta.getExprPos(cast node);
		if (exprPos != null) return exprPos;

		return {line: 0, col: 0, colStart: 0, colEnd: 0};
	}
}
