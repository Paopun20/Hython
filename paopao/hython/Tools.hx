package paopao.hython;

import paopao.hython.Expr;

class Tools {
	public static function iter(e:Expr, f:Expr->Void) {
		switch (e) {
		    case ERoot(e, pos):
				if (e != null)
					f(e);
			case EConst(_), EIdent(_):
			case EVar(_, _, e):
				if (e != null)
					f(e);
			case EParent(e):
				f(e);
			case EBlock(el):
				for (e in el)
					f(e);
			case EField(e, _):
				f(e);
			case EBinop(_, e1, e2):
				f(e1);
				f(e2);
			case EUnop(_, _, e):
				f(e);
			case ECall(e, args):
				f(e);
				for (a in args)
					f(a);
			case EIf(c, e1, e2):
				f(c);
				f(e1);
				if (e2 != null)
					f(e2);
			case EWhile(c, e):
				f(c);
				f(e);
			case EFor(_, it, e):
				f(it);
				f(e);
			case EForGen(it, e):
				f(it);
				f(e);
			case EBreak, EContinue:
			case EFunction(_, e, _, _):
				f(e);
			case EReturn(e):
				if (e != null)
					f(e);
			case EArray(e, i):
				f(e);
				f(i);
			case EArrayDecl(el):
				for (e in el)
					f(e);
			case ENew(_, el):
				for (e in el)
					f(e);
			case EThrow(e):
				f(e);
			case ETry(e, _, _, c):
				f(e);
				f(c);
			case EObject(fl):
				for (fi in fl)
					f(fi.e);
			case ETernary(c, e1, e2):
				f(c);
				f(e1);
				f(e2);
			case ESwitch(e, cases, def):
				f(e);
				for (c in cases) {
					for (v in c.values)
						f(v);
					f(c.expr);
				}
				if (def != null)
					f(def);
			case ECheckType(e, _):
				f(e);
			case EImport(_, _), EImportFrom(_, _, _):
				// Import statements don't have sub-expressions to iterate
			case EDel(e):
				f(e);
			case EAssert(cond, msg):
				f(cond);
				if (msg != null)
					f(msg);
			case EComprehension(expr, loops, _, key):
				f(expr);
				for (loop in loops) {
					f(loop.iter);
					if (loop.cond != null)
						f(loop.cond);
				}
				if (key != null)
					f(key);
			case EGenerator(expr, loops):
				f(expr);
				for (loop in loops) {
					f(loop.iter);
					if (loop.cond != null)
						f(loop.cond);
				}
			case ESlice(e, start, end, step):
				f(e);
				if (start != null)
					f(start);
				if (end != null)
					f(end);
				if (step != null)
					f(step);
			case ETuple(elements):
				for (el in elements)
					f(el);
		}
	}

	public static function map(e:Expr, f:Expr->Expr) {
		var edef = switch (e) {
		    case ERoot(_, _): ERoot(map(e, f));
			case EConst(_), EIdent(_), EBreak, EContinue: e;
			case EVar(n, t, e): EVar(n, t, if (e != null) f(e) else null);
			case EParent(e): EParent(f(e));
			case EBlock(el): EBlock([for (e in el) f(e)]);
			case EField(e, fi): EField(f(e), fi);
			case EBinop(op, e1, e2): EBinop(op, f(e1), f(e2));
			case EUnop(op, pre, e): EUnop(op, pre, f(e));
			case ECall(e, args): ECall(f(e), [for (a in args) f(a)]);
			case EIf(c, e1, e2): EIf(f(c), f(e1), if (e2 != null) f(e2) else null);
			case EWhile(c, e): EWhile(f(c), f(e));
			case EFor(v, it, e): EFor(v, f(it), f(e));
			case EForGen(it, e): EForGen(f(it), f(e));
			case EFunction(args, e, name, t): EFunction(args, f(e), name, t);
			case EReturn(e): EReturn(if (e != null) f(e) else null);
			case EArray(e, i): EArray(f(e), f(i));
			case EArrayDecl(el): EArrayDecl([for (e in el) f(e)]);
			case ENew(cl, el): ENew(cl, [for (e in el) f(e)]);
			case EThrow(e): EThrow(f(e));
			case ETry(e, v, t, c): ETry(f(e), v, t, f(c));
			case EObject(fl): EObject([for (fi in fl) {name: fi.name, e: f(fi.e)}]);
			case ETernary(c, e1, e2): ETernary(f(c), f(e1), f(e2));
			case ESwitch(e, cases, def): ESwitch(f(e), [for (c in cases) {values: [for (v in c.values) f(v)], expr: f(c.expr)}], def == null ? null : f(def));
			case ECheckType(e, t): ECheckType(f(e), t);
			case EImport(path, alias): EImport(path, alias);
			case EImportFrom(path, items, alias): EImportFrom(path, items, alias);
			case EDel(e): EDel(f(e));
			case EAssert(cond, msg): EAssert(f(cond), msg != null ? f(msg) : null);
			case EComprehension(expr, loops, isDict, key): EComprehension(f(expr), [
					for (loop in loops)
						{varname: loop.varname, iter: f(loop.iter), cond: loop.cond != null ? f(loop.cond) : null}
				], isDict, key != null ? f(key) : null);
			case EGenerator(expr, loops): EGenerator(f(expr), [
					for (loop in loops)
						{varname: loop.varname, iter: f(loop.iter), cond: loop.cond != null ? f(loop.cond) : null}
				]);
			case ESlice(e, start, end, step): ESlice(f(e), start != null ? f(start) : null, end != null ? f(end) : null, step != null ? f(step) : null);
			case ETuple(elements): ETuple([for (el in elements) f(el)]);
		}
		return edef;
	}

	public static inline function expr(e:Expr):Expr {
		// Return the expression as-is since there's no .e field anymore
		return e;
	}

	public static inline function mk(e:Expr, p:Expr):Expr {
		// Extract position from the source expression if possible
		var posInfo = getPositionInfo(p);
		return ERoot(e, posInfo);
	}

	// Helper function to extract position info from an expression
	private static function getPositionInfo(e:Expr):PositionInfo {
		switch(e) {
			case ERoot(_, pos): pos;
			// case EBreak(): pos;
			// case EContinue(): pos;
			default: {
				// Default position info if not available
				pmin: 0,
				pmax: 0,
				origin: "",
				line: 0
			}
		}
		return getPositionInfo(e);
	}
	
	public static inline function getKeyIterator<T>(e:Expr, callb:String->String->Expr->T) {
		var key = null, value = null, it = e;
		switch (it) {
			case EBinop("in", ekv, eiter):
				switch (ekv) {
					case EBinop("=>", v1, v2):
						switch ([v1, v2]) {
							case [EIdent(v1), EIdent(v2)]:
								key = v1;
								value = v2;
								it = eiter;
							default:
						}
					default:
				}
			default:
		}
		return callb(key, value, it);
	}
}
