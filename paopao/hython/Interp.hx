package paopao.hython;

import paopao.hython.Parser;
import paopao.hython.Ast;
#if sys
import sys.io.File;
#end

class Interp {
	private var globals:Map<Int, Dynamic> = new Map();
	private var locals:Array<Map<Int, Dynamic>> = [];
	private var returnValue:Dynamic = null;
	private var shouldReturn:Bool = false;

	public function new() {
		locals.push(new Map()); // global scope
	}

	private function getVar(v:VariableType):Dynamic {
		return switch v {
			case VLocal(id):
				var i = locals.length - 1;
				while (i >= 0) {
					if (locals[i].exists(id)) {
						return locals[i].get(id);
					}
					i--;
				}
				null;
			case VGlobal(id):
				globals.get(id);
			case VArg(id):
				if (locals.length > 0) {
					locals[locals.length - 1].get(id);
				} else {
					null;
				}
		};
	}

	private function setVar(v:VariableType, value:Dynamic):Void {
		switch v {
			case VLocal(id):
				locals[locals.length - 1].set(id, value);
			case VGlobal(id):
				globals.set(id, value);
			case VArg(id):
				if (locals.length > 0) {
					locals[locals.length - 1].set(id, value);
				}
		};
	}

	public function run(ast:Expr):Dynamic {
		shouldReturn = false;
		returnValue = null;
		return evalExpr(ast);
	}

	private function evalExpr(expr:Expr):Dynamic {
		// Note: We don't check shouldReturn here because it should only affect control flow within blocks/functions
		// Each function should manage its own shouldReturn state

		return switch expr.expr {
			case EConstInt(n): n;
			case EConstFloat(f): f;
			case EConstString(s): s;
			case EConstBool(b): b;
			case EConstNone: null;

			case EVar(v): getVar(v);

			case EAssign(target, op, value):
				var val = evalExpr(value);
				var result = switch op {
					case Assign: val;
					case AddAssign:
						var current = evalAssignTarget(target);
						if (Std.isOfType(current, Int) && Std.isOfType(val, Int)) {
							cast(current, Int) + cast(val, Int);
						} else if (Std.isOfType(current, Float) || Std.isOfType(val, Float)) {
							toFloat(current) + toFloat(val);
						} else {
							current + val;
						}
					case SubAssign:
						var current = evalAssignTarget(target);
						if (Std.isOfType(current, Int) && Std.isOfType(val, Int)) {
							cast(current, Int) - cast(val, Int);
						} else {
							toFloat(current) - toFloat(val);
						}
					case MulAssign:
						var current = evalAssignTarget(target);
						if (Std.isOfType(current, Int) && Std.isOfType(val, Int)) {
							cast(current, Int) * cast(val, Int);
						} else {
							toFloat(current) * toFloat(val);
						}
					case DivAssign:
						var current = evalAssignTarget(target);
						toFloat(current) / toFloat(val);
				};
				applyAssignTarget(target, result);
				result;

			case EBinop(op, left, right):
				var l = evalExpr(left);
				var r = evalExpr(right);
				evalBinop(op, l, r);

			case EUnop(op, operand):
				var val = evalExpr(operand);
			var result = evalUnop(op, val);
			// For INC/DEC, we need to update the variable
			if ((op == INC || op == DEC) && operand.expr.match(EVar(_))) {
				var varRef = operand.expr;
				switch varRef {
					case EVar(v):
						setVar(v, result);
					default:
				}
			}
			result;

		case EIf(cond, thenExpr, elseExpr):
			if (isTruthy(evalExpr(cond))) {
				evalExpr(thenExpr);
			} else {
				evalExpr(elseExpr);
			}

		case EWhile(cond, body):
			var result = null;
			while (isTruthy(evalExpr(cond))) {
				result = evalExpr(body);
				if (shouldReturn)
					break;
			}
			result;

		case EBlock(exprs):
			var result = null;
			for (e in exprs) {
				result = evalExpr(e);
				if (shouldReturn)
					break;
			}
			result;

		case EFunction(args, body):
			new HythonFunction(args, body, this);

		case ECall(func, args):
			var f = evalExpr(func);
			if (Std.isOfType(f, HythonFunction)) {
				var hf = cast(f, HythonFunction);
				var argValues = [for (a in args) evalExpr(a)];
				hf.call(argValues);
			} else {
				throw "Not a function";
			}

		case EReturn(e):
			shouldReturn = true;
			returnValue = evalExpr(e);
			returnValue;

		case EField(obj, name):
			var o = evalExpr(obj);
			if (Std.isOfType(o, haxe.ds.StringMap)) {
				cast(o, haxe.ds.StringMap<Dynamic>).get(name);
			} else {
				Reflect.field(o, name);
			}

			case EIndex(obj, index):
				var o = evalExpr(obj);
				var i = evalExpr(index);
				if (Std.isOfType(o, Array)) {
					cast(o, Array<Dynamic>)[cast(i, Int)];
				} else if (Std.isOfType(o, String)) {
					cast(o, String).charAt(cast(i, Int));
				} else {
					null;
				}

			case EObject(fields):
				var obj = new haxe.ds.StringMap<Dynamic>();
				for (f in fields) {
					obj.set(f.name, evalExpr(f.expr));
				}
				obj;

			case EImport(_, _):
				null; // TODO: implement import

			case EImportFrom(_, _):
				null; // TODO: implement import from

			case ESwitch(_, _, _):
				null; // TODO: implement switch

			case EInfo(_):
				null;
		};
	}

	private function evalAssignTarget(target:AssignTarget):Dynamic {
		return switch target {
			case TVar(v): getVar(v);
			case TField(obj, name):
				var o = evalExpr(obj);
				if (Std.isOfType(o, haxe.ds.StringMap)) {
					cast(o, haxe.ds.StringMap<Dynamic>).get(name);
				} else {
					Reflect.field(o, name);
				}
			case TIndex(obj, index):
				var o = evalExpr(obj);
				var i = evalExpr(index);
				if (Std.isOfType(o, Array)) {
					cast(o, Array<Dynamic>)[cast(i, Int)];
				} else {
					null;
				}
			case TTuple(_): null; // TODO: implement tuple assignment
		};
	}

	private function applyAssignTarget(target:AssignTarget, value:Dynamic):Void {
		switch target {
			case TVar(v):
				setVar(v, value);
			case TField(obj, name):
				var o = evalExpr(obj);
				if (Std.isOfType(o, haxe.ds.StringMap)) {
					cast(o, haxe.ds.StringMap<Dynamic>).set(name, value);
				} else {
					Reflect.setField(o, name, value);
				}
			case TIndex(obj, index):
				var o = evalExpr(obj);
				var i = evalExpr(index);
				if (Std.isOfType(o, Array)) {
					cast(o, Array<Dynamic>)[cast(i, Int)] = value;
				}
			case TTuple(_):
				// TODO: implement tuple assignment
		};
	}

	private function evalBinop(op:ExprBinop, left:Dynamic, right:Dynamic):Dynamic {
		return switch op {
			case ADD:
				if (Std.isOfType(left, String) || Std.isOfType(right, String)) {
					Std.string(left) + Std.string(right);
				} else if (Std.isOfType(left, Int) && Std.isOfType(right, Int)) {
					cast(left, Int) + cast(right, Int);
				} else {
					toFloat(left) + toFloat(right);
				}
			case SUB:
				if (Std.isOfType(left, Int) && Std.isOfType(right, Int)) {
					cast(left, Int) - cast(right, Int);
				} else {
					toFloat(left) - toFloat(right);
				}
			case MUL:
				if (Std.isOfType(left, Int) && Std.isOfType(right, Int)) {
					cast(left, Int) * cast(right, Int);
				} else {
					toFloat(left) * toFloat(right);
				}
			case DIV:
				toFloat(left) / toFloat(right);
			case MOD:
				if (Std.isOfType(left, Int) && Std.isOfType(right, Int)) {
					cast(left, Int) % cast(right, Int);
				} else {
					toFloat(left) % toFloat(right);
				}
			case EQ: left == right;
			case NEQ: left != right;
			case LT: compare(left, right) < 0;
			case GT: compare(left, right) > 0;
			case LTE: compare(left, right) <= 0;
			case GTE: compare(left, right) >= 0;
			case AND: isTruthy(left) && isTruthy(right);
			case OR: isTruthy(left) || isTruthy(right);
		};
	}

	private function evalUnop(op:ExprUnop, operand:Dynamic):Dynamic {
		return switch op {
			case NEG:
				if (Std.isOfType(operand, Int)) {
					-cast(operand, Int);
				} else {
					-toFloat(operand);
				}
			case NOT:
				!isTruthy(operand);
			case NEG_BIT:
				if (Std.isOfType(operand, Int)) {
					~cast(operand, Int);
				} else {
					0;
				}
			case INC:
				if (Std.isOfType(operand, Int)) {
					cast(operand, Int) + 1;
				} else {
					toFloat(operand) + 1;
				}
			case DEC:
				if (Std.isOfType(operand, Int)) {
					cast(operand, Int) - 1;
				} else {
					toFloat(operand) - 1;
				}
		};
	}

	private function isTruthy(value:Dynamic):Bool {
		if (value == null)
			return false;
		if (Std.isOfType(value, Bool))
			return cast(value, Bool);
		if (Std.isOfType(value, Int))
			return cast(value, Int) != 0;
		if (Std.isOfType(value, Float))
			return cast(value, Float) != 0.0;
		if (Std.isOfType(value, String))
			return cast(value, String) != "";
		return true;
	}

	private function toFloat(value:Dynamic):Float {
		if (Std.isOfType(value, Float))
			return cast(value, Float);
		if (Std.isOfType(value, Int))
			return cast(value, Int);
		if (Std.isOfType(value, String))
			return Std.parseFloat(cast(value, String));
		return 0.0;
	}

	private function compare(left:Dynamic, right:Dynamic):Int {
		if (Std.isOfType(left, Int) && Std.isOfType(right, Int)) {
			var l = cast(left, Int);
			var r = cast(right, Int);
			if (l < r)
				return -1;
			if (l > r)
				return 1;
			return 0;
		} else if (Std.isOfType(left, String) && Std.isOfType(right, String)) {
			var l = cast(left, String);
			var r = cast(right, String);
			if (l < r)
				return -1;
			if (l > r)
				return 1;
			return 0;
		} else {
			var l = toFloat(left);
			var r = toFloat(right);
			if (l < r)
				return -1;
			if (l > r)
				return 1;
			return 0;
		}
	}

	// static function
	public static function runFromFile(filename:String):Void {
		#if sys
		var source = File.getContent(filename);
		var parser = new Parser(source);
		var ast = parser.parse();
		var interp = new Interp();
		interp.run(ast);
		#end
	}

	public static function runFromSource(source:String):Void {
		var parser = new Parser(source);
		var ast = parser.parse();
		var interp = new Interp();
		interp.run(ast);
	}
}

class HythonFunction {
	private var args:Array<Argument>;
	private var body:Expr;
	private var interp:Interp;

	public function new(args:Array<Argument>, body:Expr, interp:Interp) {
		this.args = args;
		this.body = body;
		this.interp = interp;
	}

	public function call(argValues:Array<Dynamic>):Dynamic {
		@:privateAccess {
			// Create new scope
			interp.locals.push(new Map());

			// Bind arguments
			for (i in 0...args.length) {
				if (i < argValues.length) {
					switch args[i].name {
						case VArg(id):
							interp.locals[interp.locals.length - 1].set(id, argValues[i]);
						default:
					}
				}
			}

			// Execute body
			var prevShouldReturn = interp.shouldReturn;
			interp.shouldReturn = false;
			var result = interp.evalExpr(body);
			var returnVal = interp.returnValue;
			interp.shouldReturn = prevShouldReturn;
			interp.returnValue = null;

			// Pop scope
			interp.locals.pop();

			return returnVal != null ? returnVal : result;
		}
	}
}
