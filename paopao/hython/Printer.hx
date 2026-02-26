package paopao.hython;

import paopao.hython.Expr;

class Printer {
	var buf:StringBuf;
	var tabs:String;

	public function new() {}

	public function exprToString(e:Expr) {
		buf = new StringBuf();
		tabs = "";
		expr(e);
		return buf.toString();
	}

	public function typeToString(t:CType) {
		buf = new StringBuf();
		tabs = "";
		type(t);
		return buf.toString();
	}

	inline function add<T>(s:T)
		buf.add(s);

	private function type(t:CType) {
		switch (t) {
			case CTOpt(t):
				add("?");
				type(t);

			case CTPath(path, params):
				add(path.join("."));
				if (params != null && params.length > 0) {
					add("<");
					var first = true;
					for (p in params) {
						if (first)
							first = false
						else
							add(", ");
						type(p);
					}
					add(">");
				}

			case CTNamed(name, t):
				add(name);
				add(":");
				type(t);

			case CTFun(args, ret) if (Lambda.exists(args, a -> a.match(CTNamed(_, _)))):
				add("(");
				var first = true;
				for (a in args) {
					if (first)
						first = false
					else
						add(", ");
					switch (a) {
						case CTNamed(_, _): type(a);
						default: type(CTNamed("_", a));
					}
				}
				add(") -> ");
				type(ret);

			case CTFun(args, ret):
				if (args.length == 0) {
					add("Void -> ");
				} else {
					for (a in args) {
						type(a);
						add(" -> ");
					}
				}
				type(ret);

			case CTAnon(fields):
				add("{");
				var first = true;
				for (f in fields) {
					if (first) {
						first = false;
						add(" ");
					} else {
						add(", ");
					}
					add(f.name + " : ");
					type(f.t);
				}
				add(first ? "}" : " }");

			case CTParent(t):
				add("(");
				type(t);
				add(")");

			case CTExpr(e):
				expr(e);
		}
	}

	private function addType(t:CType) {
		if (t != null) {
			add(" : ");
			type(t);
		}
	}

	private function addConst(c:Const) {
		switch (c) {
			case CInt(i):
				add(i);
			case CFloat(f):
				add(f);
			case CString(s):
				add('"');
				add(s.split('"')
					.join('\\"')
					.split("\n")
					.join("\\n")
					.split("\r")
					.join("\\r")
					.split("\t")
					.join("\\t"));
				add('"');
		}
	}

	private function expr(e:Expr) {
		if (e == null) {
			add("??NULL??");
			return;
		}

		switch (e) {
			case EConst(c):
				addConst(c);
			case EClass(name, baseClasses, body):
				add("class " + name);
				if (baseClasses.length > 0) {
					add(" extends ");
					for (i in 0...baseClasses.length) {
						if (i > 0) {
							add(", ");
						}
						expr(baseClasses[i]);
					}
				}
				add(" {\n");
				tabs += "\t";
				tabs = tabs.substr(1);
				add("}");

			case EIdent(v):
				add(v);

			case EVar(n, t, e):
				add("var " + n);
				addType(t);
				if (e != null) {
					add(" = ");
					expr(e);
				}

			case EParent(e):
				add("(");
				expr(e);
				add(")");

			case EBlock(el):
				if (el.length == 0) {
					add("{}");
				} else {
					add("{\n");
					tabs += "\t";
					for (e in el) {
						add(tabs);
						expr(e);
						add(";\n");
					}
					tabs = tabs.substr(1);
					add("}");
				}

			case EField(e, f):
				expr(e);
				add("." + f);

			case EBinop(op, e1, e2):
				expr(e1);
				add(" " + op + " ");
				expr(e2);

			case EUnop(op, pre, e):
				if (pre) {
					add(op);
					expr(e);
				} else {
					expr(e);
					add(op);
				}

			case ECall(e, args):
				switch (e) {
					case EIdent(_), EField(_, _), EConst(_):
						expr(e);
					default:
						add("(");
						expr(e);
						add(")");
				}
				add("(");
				var first = true;
				for (a in args) {
					if (first)
						first = false
					else
						add(", ");
					expr(a);
				}
				add(")");

			case EIf(cond, e1, e2):
				add("if ");
				expr(cond);
				add(" ");
				expr(e1);
				if (e2 != null) {
					add(" else ");
					expr(e2);
				}

			case EWhile(cond, e):
				add("while ");
				expr(cond);
				add(" ");
				expr(e);

			case EFor(v, it, e):
				add("for " + v + " in ");
				expr(it);
				add(" ");
				expr(e);

			case EForGen(it, e):
				add("for ");
				expr(it);
				add(" ");
				expr(e);

			case EBreak:
				add("break");

			case EContinue:
				add("continue");

			case EFunction(args, e, name, ret):
				add("def");
				if (name != null)
					add(" " + name);
				add("(");
				var first = true;
				for (a in args) {
					if (first)
						first = false
					else
						add(", ");
					if (a.opt)
						add("?");
					add(a.name);
					addType(a.t);
				}
				add(")");
				addType(ret);
				add(" ");
				expr(e);

			case EReturn(e):
				add("return");
				if (e != null) {
					add(" ");
					expr(e);
				}

			case EArray(e, i):
				expr(e);
				add("[");
				expr(i);
				add("]");

			case EArrayDecl(el):
				add("[");
				var first = true;
				for (e in el) {
					if (first)
						first = false
					else
						add(", ");
					expr(e);
				}
				add("]");

			case ENew(cl, args):
				add("new " + cl + "(");
				var first = true;
				for (e in args) {
					if (first)
						first = false
					else
						add(", ");
					expr(e);
				}
				add(")");

			case EThrow(e):
				add("throw ");
				expr(e);

			case ETry(e, v, t, c):
				add("try ");
				expr(e);
				add(" catch(" + v);
				addType(t);
				add(") ");
				expr(c);

			case EObject(fl):
				add("{\n");
				tabs += "\t";
				for (f in fl) {
					add(tabs + f.name + " : ");
					expr(f.e);
					add(",\n");
				}
				tabs = tabs.substr(1);
				add("}");

			case ETernary(c, e1, e2):
				expr(c);
				add(" ? ");
				expr(e1);
				add(" : ");
				expr(e2);

			case ESwitch(e, cases, def):
				add("match ");
				expr(e);
				add(":\n");
				tabs += "\t";
				for (c in cases) {
					add(tabs + "case ");
					var first = true;
					for (v in c.values) {
						if (first)
							first = false
						else
							add(", ");
						expr(v);
					}
					add(":\n");
					add(tabs + "\t");
					expr(c.expr);
					add("\n");
				}
				if (def != null) {
					add(tabs + "case _:\n");
					add(tabs + "\t");
					expr(def);
					add("\n");
				}
				tabs = tabs.substr(1);

			case ECheckType(e, t):
				add("(");
				expr(e);
				add(" : ");
				type(t);
				add(")");

			case EAssert(e, msg):
				add("assert ");
				expr(e);
				if (msg != null) {
					add(", ");
					expr(msg);
				}

			case EComprehension(e, loops, isDict, key):
				add(isDict ? "{" : "[");
				if (isDict && key != null) {
					expr(key);
					add(": ");
				}
				expr(e);
				for (l in loops) {
					add(" for " + l.varname + " in ");
					expr(l.iter);
					if (l.cond != null) {
						add(" if ");
						expr(l.cond);
					}
				}
				add(isDict ? "}" : "]");

			case EGenerator(e, loops):
				add("(");
				expr(e);
				for (l in loops) {
					add(" for " + l.varname + " in ");
					expr(l.iter);
				}
				add(")");

			case EDel(e):
				add("del ");
				expr(e);

			case EImport(path, alias):
				add("import " + path.join("."));
				if (alias != null)
					add(" as " + alias);

			case EImportFrom(path, items, alias):
				add("from " + path.join(".") + " import ");
				var first = true;
				for (i in items) {
					if (first)
						first = false
					else
						add(", ");
					add(i);
				}
				if (alias != null)
					add(" as " + alias);

			case ESlice(e, s, end, step):
				expr(e);
				add("[");
				if (s != null)
					expr(s);
				add(":");
				if (end != null)
					expr(end);
				if (step != null) {
					add(":");
					expr(step);
				}
				add("]");

			case ETuple(el):
				add("(");
				var first = true;
				for (e in el) {
					if (first)
						first = false
					else
						add(", ");
					expr(e);
				}
				if (el.length == 1)
					add(",");
				add(")");

			case ERoot(e, _):
				if (e != null)
					expr(e);
			case EGlobal(varOnGlobal):
			    add("global");
		}
	}

	public static function toString(e:Expr) {
		return new Printer().exprToString(e);
	}

	public static function errorToString(e:Error) {
		return switch (e) {
			case EInvalidChar(c):
				"Invalid character: " + c;
			case EUnexpected(s):
				"Unexpected token: " + s;
			case EUnterminatedString:
				"Unterminated string";
			case EUnterminatedComment:
				"Unterminated comment";
			case EInvalidPreprocessor(msg):
				"Invalid preprocessor: " + msg;
			case EUnknownVariable(v):
				"Unknown variable: " + v;
			case EInvalidIterator(v):
				"Invalid iterator: " + v;
			case EInvalidOp(op):
				"Invalid operator: " + op;
			case EInvalidAccess(f):
				"Invalid access: " + f;
			case ECustom(msg):
				msg;
			case ETypeError(msg):
				"TypeError: " + msg;
			case EValueError(msg):
				"ValueError: " + msg;
			case ETabError(msg):
				"TabError: " + msg;
			case EZeroDivisionError(msg):
				"ZeroDivisionError: " + msg;
			case EExitException(code):
				"Exit(" + code + ")";
			case ERecursionError(msg):
				"RecursionError: " + msg;
			case EAssertionError(msg):
				"AssertionError: " + msg;
			case ENameError(msg):
				"NameError: " + msg;
			case EKeyError(msg):
				"KeyError: " + msg;
			case EClassNotAllowed(msg):
				"ClassNotAllowed: " + msg;
			case ESyntaxError(msg):
				"SyntaxError: " + msg;
		}
	}
}
