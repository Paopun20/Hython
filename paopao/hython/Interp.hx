package paopao.hython;

import paopao.hython.Expr;
import haxe.Constraints.IMap;
import haxe.ds.StringMap;

enum PyResult {
	Success(value:PyValue);
	Failure(error:Expr);
}

enum PyValue {
	PyNumber(value:Float);
	PyString(value:String);
	PyBool(value:Bool);
	PyList(value:Array<PyValue>);
	PyDict(value:StringMap<PyValue>);
	PyClass(value:Class<PyValue>);
	PyFunction(value:(...PyValue) -> Null<PyValue>);
	PyNone(value:Null<Dynamic>);
}

private enum Stop {
	SBreak;
	SContinue;
	SReturn;
}

class Interp {
	// Public API
	public var errorHandler:Error->Void;
	public var maxDepth:Int = 1000;
	public var allowStaticAccess:Bool = true;
	public var allowClassResolve:Bool = true;

	// Internal state
	private var locals:Map<String, {r:Dynamic}>;
	private var globals:StringMap<Dynamic>;
	private var binops:Map<String, Expr->Expr->Dynamic>;
	private var depth:Int;
	private var inTry:Bool;
	private var declared:Array<{n:String, old:{r:Dynamic}}>;
	private var returnValue:Dynamic;

	// Remove the conditional compilation
	private var curExpr:Expr;
	private var variables:StringMap<Dynamic>;
	private var shouldStop:Bool = false;

	public function new() {
		locals = new Map();
		globals = new StringMap<Dynamic>();
		declared = new Array();
		resetVariables();
		initOps();
	}

	private function resetVariables() {
		variables = new StringMap<Dynamic>();

		// Standard constants
		variables.set("__name__", "__main__");
		variables.set("__file__", null);
		variables.set("null", null);
		variables.set("true", true);
		variables.set("false", false);

		// Standard library functions
		variables.set("print", function(v:Dynamic) {
			#if sys
			Sys.println(Std.string(v));
			#else
			trace(v);
			#end
		});

		// range() function - Python-style
		variables.set("range", function(start:Dynamic, ?end:Dynamic, ?step:Dynamic) {
			var s = Std.int(start);
			var e = (end == null) ? s : Std.int(end);
			var st = (step == null) ? 1 : Std.int(step);

			if (end == null) {
				s = 0;
				e = Std.int(start);
			}

			var result = [];
			if (st > 0) {
				var i = s;
				while (i < e) {
					result.push(i);
					i += st;
				}
			} else if (st < 0) {
				var i = s;
				while (i > e) {
					result.push(i);
					i += st;
				}
			}
			return result;
		});

		// len() function - get length of strings, arrays, dicts
		variables.set("len", function(v:Dynamic) {
			if (v == null)
				return 0;
			if (Std.isOfType(v, String))
				return Std.string(v).length;
			if (Std.isOfType(v, Array))
				return cast(v, Array<Dynamic>).length;
			if (Std.isOfType(v, haxe.ds.StringMap)) {
				var count = 0;
				for (_ in cast(v, haxe.ds.StringMap<Dynamic>))
					count++;
				return count;
			}
			return 0;
		});

		// str() function - convert to string
		variables.set("str", function(v:Dynamic) {
			return Std.string(v);
		});

		// int() function - convert to integer
		variables.set("int", function(v:Dynamic):Int {
			if (v == null)
				error(EValueError('Cannot convert null to int'));

			if (Std.isOfType(v, Bool))
				return v ? 1 : 0;

			if (Std.isOfType(v, Int))
				return v;

			if (Std.isOfType(v, Float))
				return Std.int(v);

			var s = StringTools.trim(Std.string(v));
			if (s == "")
				error(EValueError('Cannot convert empty string to int'));

			var n = Std.parseInt(s);
			if (n == null)
				error(EValueError('Invalid int value: "$s"'));

			return n;
		});

		// float() function - convert to float
		variables.set("float", function(v:Dynamic) {
			if (v == null)
				return 0.0;
			if (Std.isOfType(v, Bool))
				return v ? 1.0 : 0.0;
			if (Std.isOfType(v, Float))
				return v;
			if (Std.isOfType(v, Int))
				return Std.parseFloat(Std.string(v));
			var s = StringTools.trim(Std.string(v));
			if (s == "")
				return 0.0;
			return Std.parseFloat(s);
		});

		// list() function - create or convert to list
		variables.set("list", function(?v:Dynamic) {
			if (v == null)
				return [];
			if (Std.isOfType(v, Array))
				return v;
			if (Std.isOfType(v, String)) {
				var s = cast(v, String);
				var result = [];
				for (i in 0...s.length) {
					result.push(s.charAt(i));
				}
				return result;
			}
			return [v];
		});

		// dict() function - create dictionary
		variables.set("dict", function(?v:Dynamic) {
			if (v == null)
				return new haxe.ds.StringMap<Dynamic>();

			if (Std.isOfType(v, haxe.ds.StringMap))
				return v;

			if (Std.isOfType(v, Array)) {
				var result = new haxe.ds.StringMap<Dynamic>();
				for (i in 0...v.length) {
					result.set(Std.string(i), v[i]);
				}
				return result;
			}

			var map = new haxe.ds.StringMap<Dynamic>();
			map.set("", v);
			return map;
		});

		// type() function - get type of value
		variables.set("type", function(v:Dynamic) {
			if (v == null)
				return "NoneType";
			if (Std.isOfType(v, Bool))
				return "bool";
			if (Std.isOfType(v, Int))
				return "int";
			if (Std.isOfType(v, Float))
				return "float";
			if (Std.isOfType(v, String))
				return "str";
			if (Std.isOfType(v, Array))
				return "list";
			if (Std.isOfType(v, haxe.ds.StringMap))
				return "dict";
			return "object";
		});

		// abs() function - absolute value
		variables.set("abs", function(v:Dynamic) {
			var n = Std.parseFloat(Std.string(v));
			return n < 0 ? -n : n;
		});

		// min() function - minimum value
		variables.set("min", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			if (args.length == 0)
				throw "min() requires at least 1 argument";
			if (args.length == 1 && Std.isOfType(args[0], Array)) {
				args = cast(args[0], Array<Dynamic>);
			}
			if (args.length == 0)
				throw "min() arg is an empty sequence";
			var result = args[0];
			for (i in 1...args.length) {
				var a = Std.parseFloat(Std.string(args[i]));
				var b = Std.parseFloat(Std.string(result));
				if (a < b)
					result = args[i];
			}
			return result;
		}));

		// max() function - maximum value
		variables.set("max", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			if (args.length == 0)
				throw "max() requires at least 1 argument";
			if (args.length == 1 && Std.isOfType(args[0], Array)) {
				args = cast(args[0], Array<Dynamic>);
			}
			if (args.length == 0)
				throw "max() arg is an empty sequence";
			var result = args[0];
			for (i in 1...args.length) {
				var a = Std.parseFloat(Std.string(args[i]));
				var b = Std.parseFloat(Std.string(result));
				if (a > b)
					result = args[i];
			}
			return result;
		}));

		// sum() function - sum of values
		variables.set("sum", function(iterable:Dynamic, ?start:Dynamic) {
			var result = start != null ? Std.parseFloat(Std.string(start)) : 0.0;
			if (Std.isOfType(iterable, Array)) {
				var arr = cast(iterable, Array<Dynamic>);
				for (item in arr) {
					result += Std.parseFloat(Std.string(item));
				}
			}
			return result;
		});

		// bool() function - convert to boolean
		variables.set("bool", function(v:Dynamic) {
			if (v == null)
				return false;
			if (Std.isOfType(v, Bool))
				return v;
			if (Std.isOfType(v, Int))
				return v != 0;
			if (Std.isOfType(v, Float))
				return v != 0.0;
			if (Std.isOfType(v, String))
				return Std.string(v) != "";
			if (Std.isOfType(v, Array))
				return cast(v, Array<Dynamic>).length > 0;
			return true;
		});

		// ord() function - get character code
		variables.set("ord", function(s:Dynamic) {
			var str = Std.string(s);
			if (str.length == 0)
				throw "ord() expected a character";
			var idx:Int = 0;
			return str.charCodeAt(idx);
		});

		// chr() function - get character from code
		variables.set("chr", function(code:Dynamic) {
			return String.fromCharCode(Std.int(code));
		});

		// round() function - round number
		variables.set("round", function(v:Dynamic, ?digits:Dynamic) {
			var num = Std.parseFloat(Std.string(v));
			var d = digits != null ? Std.int(digits) : 0;
			var factor = Math.pow(10, d);
			return Math.round(num * factor) / factor;
		});

		// pow() function - power/exponentiation
		variables.set("pow", function(base:Dynamic, exp:Dynamic) {
			return Math.pow(Std.parseFloat(Std.string(base)), Std.parseFloat(Std.string(exp)));
		});

		// sqrt() function - square root
		variables.set("sqrt", function(v:Dynamic) {
			return Math.sqrt(Std.parseFloat(Std.string(v)));
		});

		// sorted() function - sort a list
		variables.set("sorted", function(iterable:Dynamic, ?reverse:Dynamic) {
			var arr:Array<Dynamic> = [];
			if (Std.isOfType(iterable, Array)) {
				arr = cast(iterable, Array<Dynamic>).copy();
			} else if (Std.isOfType(iterable, String)) {
				var s = cast(iterable, String);
				for (i in 0...s.length) {
					arr.push(s.charAt(i));
				}
			}
			arr.sort(function(a, b) {
				if (a < b)
					return -1;
				if (a > b)
					return 1;
				return 0;
			});
			if (reverse == true)
				arr.reverse();
			return arr;
		});

		// reversed() function - reverse a list
		variables.set("reversed", function(iterable:Dynamic) {
			var arr:Array<Dynamic> = [];
			if (Std.isOfType(iterable, Array)) {
				arr = cast(iterable, Array<Dynamic>).copy();
			} else if (Std.isOfType(iterable, String)) {
				var s = cast(iterable, String);
				for (i in 0...s.length) {
					arr.push(s.charAt(i));
				}
			}
			arr.reverse();
			return arr;
		});

		// enumerate() function - get index and value pairs
		variables.set("enumerate", function(iterable:Dynamic, ?start:Dynamic) {
			var result:Array<Dynamic> = [];
			var startIdx = start != null ? Std.int(start) : 0;
			if (Std.isOfType(iterable, Array)) {
				var arr = cast(iterable, Array<Dynamic>);
				var i = 0;
				while (i < arr.length) {
					result.push([startIdx + i, arr[i]]);
					i++;
				}
			} else if (Std.isOfType(iterable, String)) {
				var s = cast(iterable, String);
				var i = 0;
				while (i < s.length) {
					result.push([startIdx + i, s.charAt(i)]);
					i++;
				}
			}
			return result;
		});

		// zip() function - combine multiple iterables
		variables.set("zip", Reflect.makeVarArgs(function(iterables:Array<Dynamic>) {
			if (iterables.length == 0)
				return [];
			var result:Array<Dynamic> = [];
			var minLen = 0x7FFFFFFF;
			for (it in iterables) {
				if (Std.isOfType(it, Array)) {
					minLen = Std.int(Math.min(minLen, cast(it, Array<Dynamic>).length));
				}
			}
			for (i in 0...minLen) {
				var tuple = [];
				for (it in iterables) {
					if (Std.isOfType(it, Array)) {
						tuple.push(cast(it, Array<Dynamic>)[i]);
					}
				}
				result.push(tuple);
			}
			return result;
		}));

		// any() function - check if any element is true
		variables.set("any", function(iterable:Dynamic) {
			if (Std.isOfType(iterable, Array)) {
				for (item in cast(iterable, Array<Dynamic>)) {
					if (item == true || (item != null && item != false && item != 0 && item != "")) {
						return true;
					}
				}
			}
			return false;
		});

		// all() function - check if all elements are true
		variables.set("all", function(iterable:Dynamic) {
			if (Std.isOfType(iterable, Array)) {
				for (item in cast(iterable, Array<Dynamic>)) {
					if (item == false || item == null || item == 0 || item == "") {
						return false;
					}
				}
				return true;
			}
			return false;
		});

		// isinstance() function - check if value is of a type
		variables.set("isinstance", function(v:Dynamic, type:Dynamic) {
			if (Std.isOfType(type, String)) {
				var typeName = cast(type, String);
				if (typeName == "int")
					return Std.isOfType(v, Int) || (Std.isOfType(v, Float) && v == Std.int(v));
				if (typeName == "float")
					return Std.isOfType(v, Float);
				if (typeName == "str")
					return Std.isOfType(v, String);
				if (typeName == "bool")
					return Std.isOfType(v, Bool);
				if (typeName == "list")
					return Std.isOfType(v, Array);
				if (typeName == "dict")
					return Std.isOfType(v, haxe.ds.StringMap);
			}
			return false;
		});

		variables.set("exit", function(code:Int = 0) {
			error(EExitException(code));
		});
	}

	// Helper function to extract position info from expressions
	private function getPositionInfo(e:Expr) {
		switch (e) {
			case ERoot(_, pos):
				return {fileName: pos.origin, lineNumber: pos.line};
			default:
				return {fileName: "unknown", lineNumber: 0};
		}
	}

	private function initOps() {
		var me = this;
		binops = new Map();

		// Arithmetic operators
		binops.set("+", function(e1, e2) {
			return me.expr(e1) + me.expr(e2);
		});
		binops.set("-", function(e1, e2) {
			return me.expr(e1) - me.expr(e2);
		});
		binops.set("*", function(e1, e2) {
			return me.expr(e1) * me.expr(e2);
		});
		binops.set("/", function(e1, e2) {
			if (me.expr(e2) == 0) {
				error(EZeroDivisionError("Division by zero"));
			}
			return me.expr(e1) / me.expr(e2);
		});
		binops.set("%", function(e1, e2) {
			return me.expr(e1) % me.expr(e2);
		});

		// Bitwise operators
		binops.set("&", function(e1, e2) {
			return me.expr(e1) & me.expr(e2);
		});
		binops.set("|", function(e1, e2) {
			return me.expr(e1) | me.expr(e2);
		});
		binops.set("^", function(e1, e2) {
			return me.expr(e1) ^ me.expr(e2);
		});
		binops.set("<<", function(e1, e2) {
			return me.expr(e1) << me.expr(e2);
		});
		binops.set(">>", function(e1, e2) {
			return me.expr(e1) >> me.expr(e2);
		});
		binops.set(">>>", function(e1, e2) {
			return me.expr(e1) >>> me.expr(e2);
		});

		// Comparison operators
		binops.set("==", function(e1, e2) {
			return me.expr(e1) == me.expr(e2);
		});
		binops.set("!=", function(e1, e2) {
			return me.expr(e1) != me.expr(e2);
		});
		binops.set(">=", function(e1, e2) {
			return me.expr(e1) >= me.expr(e2);
		});
		binops.set("<=", function(e1, e2) {
			return me.expr(e1) <= me.expr(e2);
		});
		binops.set(">", function(e1, e2) {
			return me.expr(e1) > me.expr(e2);
		});
		binops.set("<", function(e1, e2) {
			return me.expr(e1) < me.expr(e2);
		});

		// Logical operators with short-circuit evaluation
		binops.set("||", function(e1, e2) {
			var v1 = me.expr(e1);
			if (v1 == true)
				return true;
			return me.expr(e2) == true;
		});
		binops.set("&&", function(e1, e2) {
			var v1 = me.expr(e1);
			if (v1 != true)
				return false;
			return me.expr(e2) == true;
		});

		// Python-style logical operators
		binops.set("or", function(e1, e2) {
			var v1 = me.expr(e1);
			if (isTruthy(v1))
				return v1;
			return me.expr(e2);
		});
		binops.set("and", function(e1, e2) {
			var v1 = me.expr(e1);
			if (!isTruthy(v1))
				return v1;
			return me.expr(e2);
		});

		// Special operators
		binops.set("=", assign);
		binops.set("...", function(e1, e2) return new IntIterator(me.expr(e1), me.expr(e2)));
		binops.set("is", function(e1, e2) {
			var v1 = me.expr(e1);
			var v2 = me.expr(e2);
			return v1 == v2; // Python 'is' checks identity (object reference equality)
		});
		binops.set("is not", function(e1, e2) {
			var v1 = me.expr(e1);
			var v2 = me.expr(e2);
			return v1 != v2;
		});
		binops.set("not in", function(e1, e2) {
			var v1 = me.expr(e1);
			var v2 = me.expr(e2);
			if (Std.isOfType(v2, Array)) {
				var arr = cast(v2, Array<Dynamic>);
				return arr.indexOf(v1) == -1;
			} else if (Std.isOfType(v2, String)) {
				return cast(v2, String).indexOf(Std.string(v1)) == -1;
			}
			return true;
		});
		binops.set("in", function(e1, e2) {
			var v1 = me.expr(e1);
			var v2 = me.expr(e2);
			if (Std.isOfType(v2, Array)) {
				var arr = cast(v2, Array<Dynamic>);
				return arr.indexOf(v1) != -1;
			} else if (Std.isOfType(v2, String)) {
				return cast(v2, String).indexOf(Std.string(v1)) != -1;
			} else if (isMap(v2)) {
				return getMapValue(v2, v1) != null;
			}
			return false;
		});

		// Assignment operators
		assignOp("+=", function(v1:Dynamic, v2:Dynamic) {
			return v1 + v2;
		});
		assignOp("-=", function(v1:Float, v2:Float) {
			return v1 - v2;
		});
		assignOp("*=", function(v1:Float, v2:Float) {
			return v1 * v2;
		});
		assignOp("/=", function(v1:Float, v2:Float) {
			if (v2 == 0) {
				error(EZeroDivisionError("Division by zero"));
			}
			return v1 / v2;
		});
		assignOp("%=", function(v1:Float, v2:Float) {
			return v1 % v2;
		});
		assignOp("&=", function(v1, v2) {
			return v1 & v2;
		});
		assignOp("|=", function(v1, v2) {
			return v1 | v2;
		});
		assignOp("^=", function(v1, v2) {
			return v1 ^ v2;
		});
		assignOp("<<=", function(v1, v2) {
			return v1 << v2;
		});
		assignOp(">>=", function(v1, v2) {
			return v1 >> v2;
		});
		assignOp(">>>=", function(v1, v2) {
			return v1 >>> v2;
		});
	}

	public function setVar(name:String, v:Dynamic):Dynamic {
		variables.set(name, v);
		return v;
	}

	public function getVar(name:String):Dynamic {
		return variables.get(name);
	}

	public function delVar(name:String):Dynamic {
		return variables.remove(name);
	}

	private function assign(e1:Expr, e2:Expr):Dynamic {
		var v = expr(e2);
		switch (Tools.expr(e1)) {
			case EIdent(id):
				var l = locals.get(id);
				if (l == null)
					setVar(id, v);
				else
					l.r = v;
			case EField(e, f):
				v = set(expr(e), f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) {
					setMapValue(arr, index, v);
				} else {
					arr[index] = v;
				}
			default:
				error(EInvalidOp("="));
		}
		return v;
	}

	private function assignOp(op:String, fop:Dynamic->Dynamic->Dynamic) {
		var me = this;
		binops.set(op, function(e1, e2) return me.evalAssignOp(op, fop, e1, e2));
	}

	private function evalAssignOp(op:String, fop:Dynamic->Dynamic->Dynamic, e1:Expr, e2:Expr):Dynamic {
		var v;
		switch (Tools.expr(e1)) {
			case EIdent(id):
				var l = locals.get(id);
				v = fop(expr(e1), expr(e2));
				if (l == null)
					setVar(id, v);
				else
					l.r = v;
			case EField(e, f):
				var obj = expr(e);
				v = fop(get(obj, f), expr(e2));
				v = set(obj, f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) {
					v = fop(getMapValue(arr, index), expr(e2));
					setMapValue(arr, index, v);
				} else {
					v = fop(arr[index], expr(e2));
					arr[index] = v;
				}
			default:
				return error(EInvalidOp(op));
		}
		return v;
	}

	private function increment(e:Expr, prefix:Bool, delta:Int):Dynamic {
		// Set current expression for error reporting
		curExpr = e;

		// Get the inner expression based on the new structure
		var innerExpr = switch (e) {
			case ERoot(inner, _): inner;
			default: e;
		};

		switch (innerExpr) {
			case EIdent(id):
				var l = locals.get(id);
				var v:Dynamic = (l == null) ? resolve(id) : l.r;
				if (prefix) {
					v += delta;
					if (l == null)
						setVar(id, v)
					else
						l.r = v;
				} else {
					if (l == null)
						setVar(id, v + delta)
					else
						l.r = v + delta;
				}
				return v;
			case EField(e, f):
				var obj = expr(e);
				var v:Dynamic = get(obj, f);
				if (prefix) {
					v += delta;
					set(obj, f, v);
				} else {
					set(obj, f, v + delta);
				}
				return v;
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) {
					var v = getMapValue(arr, index);
					if (prefix) {
						v += delta;
						setMapValue(arr, index, v);
					} else {
						setMapValue(arr, index, v + delta);
					}
					return v;
				} else {
					var v = arr[index];
					if (prefix) {
						v += delta;
						arr[index] = v;
					} else {
						arr[index] = v + delta;
					}
					return v;
				}
			default:
				return error(EInvalidOp((delta > 0) ? "++" : "--"));
		}
	}

	public function execute(expr:Expr):Dynamic {
		depth = 0;
		locals = new Map();
		declared = new Array();
		return exprReturn(expr);
	}

	public function stop() {
		shouldStop = true;
	}

	public function calldef(name:String, args:Array<Dynamic>):Dynamic {
		// Get the function from variables
		var f = variables.get(name);

		if (f == null) {
			error(ETypeError("Function '" + name + "' not found"));
			return null;
		}

		// Check if it's actually a function
		if (!Reflect.isFunction(f)) {
			error(ETypeError("'" + name + "' is not a function"));
			return null;
		}

		// Call the function with the provided arguments
		return Reflect.callMethod(null, f, args);
	}

	public function getdef(name:String):Bool {
		var f = variables.get(name);
		return f != null && Reflect.isFunction(f);
	}

	private function exprReturn(e:Expr):Dynamic {
		try {
			return expr(e);
		} catch (e:Stop) {
			switch (e) {
				case SBreak:
					throw "Invalid break";
				case SContinue:
					throw "Invalid continue";
				case SReturn:
					var v = returnValue;
					returnValue = null;
					return v;
			}
		}
		return null;
	}

	private function duplicate<T>(h:Map<String, T>):Map<String, T> {
		var h2 = new Map<String, T>();
		for (k in h.keys())
			h2.set(k, h.get(k));
		return h2;
	}

	private function restore(old:Int) {
		while (declared.length > old) {
			var d = declared.pop();
			locals.set(d.n, d.old);
		}
	}

	private inline function error(e:Dynamic, rethrow:Bool = false):Dynamic {
		if (errorHandler != null) {
			try {
				errorHandler(e);
			} catch (_) {}
		}

		if (rethrow) {
			this.rethrow(e);
		} else {
			throw e;
		}

		return null; // explicit, though this line is never actually reached after throw
	}

	inline function rethrow(e:Dynamic) {
		#if hl
		hl.Api.rethrow(e);
		#else
		throw e;
		#end
	}

	private function resolve(id:String):Dynamic {
		var v = variables.get(id);
		if (v == null && !variables.exists(id))
			error(EUnknownVariable(id));
		return v;
	}

	private function expr(e:Expr):Dynamic {
		// Always set current expression now since we removed conditional compilation
		curExpr = e;

		// Depth check to prevent stack overflow
		if (depth >= maxDepth)
			error(ERecursionError("Maximum recursion depth exceeded"));

		if (shouldStop) {
			shouldStop = false; // Reset the flag
			returnValue = null;
			throw SReturn;
		}

		depth++;
		var result = exprInner(e);
		depth--;

		return result;
	}

	private function exprInner(e:Expr):Dynamic {
		switch (e) {
			case ERoot(e, _):
				return exprInner(e);
			case EConst(c):
				switch (c) {
					case CInt(v): return v;
					case CFloat(f): return f;
					case CString(s): return s;
				}
			case EIdent(id):
				var l = locals.get(id);
				if (l != null)
					return l.r;
				return resolve(id);
			case EVar(n, _, e):
				var value = (e == null) ? null : expr(e);
				var l = locals.get(n);

				// Check if variable already exists in local scope
				if (l != null) {
					// Variable exists - just update it
					l.r = value;
				} else {
					// Check if it exists in global scope
					// In Python, assignment creates a NEW local variable unless it's declared global
					// So we always create a new local variable here
					declared.push({n: n, old: locals.get(n)});
					locals.set(n, {r: value});
				}
				return null;
			case EParent(e):
				return expr(e);
			case EBlock(exprs):
				var old = declared.length;
				var v = null;
				for (e in exprs)
					v = expr(e);
				restore(old);
				return v;
			case EField(e, f):
				return get(expr(e), f);
			case EBinop(op, e1, e2):
				var fop = binops.get(op);
				if (fop == null)
					error(EInvalidOp(op));
				return fop(e1, e2);
			case EUnop(op, prefix, e):
				switch (op) {
					case "!":
						return expr(e) != true;
					case "-":
						return -expr(e);
					case "++":
						return increment(e, prefix, 1);
					case "--":
						return increment(e, prefix, -1);
					case "~":
						return ~expr(e);
					default:
						error(EInvalidOp(op));
				}
			case ECall(e, params):
				var args = new Array();
				for (p in params)
					args.push(expr(p));

				switch (Tools.expr(e)) {
					case EField(e, f):
						var obj = expr(e);
						if (obj == null)
							error(EInvalidAccess(f));
						return fcall(obj, f, args);
					default:
						return call(null, expr(e), args);
				}
			case EIf(econd, e1, e2):
				return if (expr(econd) == true) expr(e1) else if (e2 == null) null else expr(e2);
			case EWhile(econd, e):
				whileLoop(econd, e);
				return null;
			case EFor(v, it, e):
				forLoop(v, it, e);
				return null;
			case EForGen(it, e):
				Tools.getKeyIterator(it, function(vk, vv, it) {
					if (vk == null) {
						// Always set current expression
						curExpr = it;
						error(EKeyError("Invalid for expression"));
						return;
					}
					forKeyValueLoop(vk, vv, it, e);
				});
				return null;
			case EBreak:
				throw SBreak;
			case EContinue:
				throw SContinue;
			case EReturn(e):
				returnValue = e == null ? null : expr(e);
				throw SReturn;
			case EFunction(params, fexpr, name, _):
				var capturedLocals = duplicate(locals);
				var me = this;
				var hasOpt = false, minParams = 0;
				for (p in params)
					if (p.opt)
						hasOpt = true;
					else
						minParams++;

				var f = function(args:Array<Dynamic>) {
					var argsLen = (args == null) ? 0 : args.length;
					if (argsLen != params.length) {
						if (argsLen < minParams) {
							var str = "Invalid number of parameters. Got " + argsLen + ", required " + minParams;
							if (name != null)
								str += " for function '" + name + "'";
							error(EKeyError(str));
						}
						// Handle optional parameters with default values
						var args2 = [];
						var pos = 0;
						for (p in params) {
							if (p.opt) {
								if (pos < argsLen) {
									args2.push(args[pos++]);
								} else {
									// Use default value
									args2.push(p.value != null ? me.expr(p.value) : null);
								}
							} else {
								args2.push(args[pos++]);
							}
						}
						args = args2;
					}

					var old = me.locals, depth = me.depth;
					me.depth++;
					me.locals = me.duplicate(capturedLocals);
					for (i in 0...params.length)
						me.locals.set(params[i].name, {r: args[i]});

					var r = null;
					var oldDecl = declared.length;
					if (inTry)
						try {
							r = me.exprReturn(fexpr);
						} catch (e:Dynamic) {
							restore(oldDecl);
							me.locals = old;
							me.depth = depth;
							#if neko
							neko.Lib.rethrow(e);
							#else
							throw e;
							#end
						}
					else
						r = me.exprReturn(fexpr);

					restore(oldDecl);
					me.locals = old;
					me.depth = depth;
					return r;
				};

				var f = Reflect.makeVarArgs(f);
				if (name != null) {
					// if (depth == 1) {
					//	// Global function
					//	variables.set(name, f);
					// } else {
					//	// Local function
					//	declared.push({n: name, old: locals.get(name)});
					//	var ref = {r: f};
					//	locals.set(name, ref);
					//	capturedLocals.set(name, ref); // Allow self-recursion
					// }

					variables.set(name, f);
				}
				return f;
			case EArrayDecl(arr):
				if (arr.length > 0 && Tools.expr(arr[0]).match(EBinop("=>", _))) {
					var keys = [];
					var values = [];
					for (e in arr) {
						switch (Tools.expr(e)) {
							case EBinop("=>", eKey, eValue):
								keys.push(expr(eKey));
								values.push(expr(eValue));
							default:
								// Always set current expression
								curExpr = e;
								error(EKeyError("Invalid map key=>value expression"));
						}
					}
					return makeMap(keys, values);
				} else {
					var a = new Array();
					for (e in arr)
						a.push(expr(e));
					return a;
				}
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
					return getMapValue(arr, index);
				return arr[index];
			case ENew(cl, params):
				var a = new Array();
				for (e in params)
					a.push(expr(e));
				return cnew(cl, a);
			case EThrow(e):
				throw expr(e);
			case ETry(e, n, _, ecatch):
				var old = declared.length;
				var oldTry = inTry;
				try {
					inTry = true;
					var v:Dynamic = expr(e);
					restore(old);
					inTry = oldTry;
					return v;
				} catch (err:Stop) {
					inTry = oldTry;
					throw err;
				} catch (err:Dynamic) {
					restore(old);
					inTry = oldTry;
					declared.push({n: n, old: locals.get(n)});
					locals.set(n, {r: err});
					var v:Dynamic = expr(ecatch);
					restore(old);
					return v;
				}
			case EObject(fl):
				var o = {};
				for (f in fl)
					set(o, f.name, expr(f.e));
				return o;
			case ETernary(econd, e1, e2):
				return if (expr(econd) == true) expr(e1) else expr(e2);
			case ESwitch(e, cases, def):
				var val:Dynamic = expr(e);
				var match = false;
				for (c in cases) {
					for (v in c.values)
						if (expr(v) == val) {
							match = true;
							break;
						}
					if (match) {
						val = expr(c.expr);
						break;
					}
				}
				if (!match)
					val = def == null ? null : expr(def);
				return val;
			case ECheckType(e, _):
				return expr(e);
			case EImport(path, alias):
				return handleImport(path, alias);
			case EImportFrom(path, items, alias):
				return handleImportFrom(path, items, alias);
			case EDel(e):
				return handleDel(e);
			case EAssert(cond, msg):
				var result = expr(cond);
				if (!isTruthy(result)) {
					var message = msg != null ? Std.string(expr(msg)) : "Assertion failed";
					error(EAssertionError(message));
				}
				return null;
			case EComprehension(expr, loops, isDict, key):
				return handleComprehension(expr, loops, isDict, key);
			case EGenerator(expr, loops):
				return handleGenerator(expr, loops);
			case ESlice(e, start, end, step):
				return handleSlice(e, start, end, step);
			case ETuple(elements):
				var result = [];
				for (el in elements)
					result.push(expr(el));
				return result;
		}
		return null;
	}

	private function handleDel(e:Expr):Dynamic {
		switch (Tools.expr(e)) {
			case EIdent(id):
				var l = locals.get(id);
				if (l != null) {
					locals.remove(id);
				} else {
					variables.remove(id);
				}
				return null;
			case EArray(arr, index):
				var a:Dynamic = expr(arr);
				var idx:Dynamic = expr(index);
				if (isMap(a)) {
					setMapValue(a, idx, null);
				} else {
					cast(a, Array<Dynamic>)[idx] = null;
				}
				return null;
			case EField(obj, field):
				var o = expr(obj);
				set(o, field, null);
				return null;
			default:
				error(ENameError("Invalid del target"));
				return null;
		}
	}

	private function handleComprehension(exprNode:Expr, loops:Array<{varname:String, iter:Expr, ?cond:Expr}>, isDict:Bool, key:Null<Expr>):Dynamic {
		var result:Dynamic = isDict ? new haxe.ds.StringMap<Dynamic>() : [];

		var me = this;

		// Recursive function to handle nested loops
		function iterate(loopIndex:Int) {
			if (loopIndex >= loops.length) {
				// We've set all loop variables, now evaluate the expression
				if (isDict) {
					var map = cast(result, haxe.ds.StringMap<Dynamic>);
					var k = key != null ? me.expr(key) : null;
					var v = me.expr(exprNode);
					if (k != null) {
						setMapValue(map, k, v);
					}
				} else {
					var arr = cast(result, Array<Dynamic>);
					arr.push(me.expr(exprNode));
				}
				return;
			}

			var loop = loops[loopIndex];
			var iterable = me.expr(loop.iter);
			var it = makeIterator(iterable);

			var oldVar = locals.get(loop.varname);
			var oldDeclLen = declared.length;
			declared.push({n: loop.varname, old: oldVar});

			while (it.hasNext()) {
				var val = it.next();
				locals.set(loop.varname, {r: val});

				// Check condition if present
				var passCondition = true;
				if (loop.cond != null) {
					passCondition = isTruthy(me.expr(loop.cond));
				}

				if (passCondition) {
					// Continue to next loop level
					iterate(loopIndex + 1);
				}
			}

			// Restore variable
			restore(oldDeclLen);
		}

		iterate(0);
		return result;
	}

	private function handleGenerator(exprNode:Expr, loops:Array<{varname:String, iter:Expr, ?cond:Expr}>):Dynamic {
		// Generator returns an array for now (full generator support would require coroutines)
		var result:Array<Dynamic> = [];
		var iterators:Array<Iterator<Dynamic>> = [];

		var me = this;
		for (loop in loops) {
			var iterable = expr(loop.iter);
			iterators.push(makeIterator(iterable));
		}

		function iterate(level:Int, values:Array<Dynamic>) {
			if (level >= loops.length) {
				var allPass = true;
				for (i in 0...loops.length) {
					if (loops[i].cond != null) {
						locals.set(loops[i].varname, {r: values[i]});
						if (!isTruthy(me.expr(loops[i].cond))) {
							allPass = false;
							break;
						}
					}
				}

				if (allPass) {
					for (i in 0...loops.length) {
						locals.set(loops[i].varname, {r: values[i]});
					}
					result.push(me.expr(exprNode));
				}
				return;
			}

			var it = iterators[level];
			var old = locals.get(loops[level].varname);
			while (it.hasNext()) {
				var val = it.next();
				locals.set(loops[level].varname, {r: val});
				var newValues = values.copy();
				newValues.push(val);
				iterate(level + 1, newValues);
			}
			if (old != null)
				locals.set(loops[level].varname, old);
			else
				locals.remove(loops[level].varname);
		}

		iterate(0, []);
		return result;
	}

	private function handleSlice(e:Expr, start:Null<Expr>, end:Null<Expr>, step:Null<Expr>):Dynamic {
		var arr:Dynamic = expr(e);
		var s = start != null ? Std.int(expr(start)) : null;
		var en = end != null ? Std.int(expr(end)) : null;
		var st = step != null ? Std.int(expr(step)) : 1;

		if (Std.isOfType(arr, Array)) {
			var a = cast(arr, Array<Dynamic>);
			var len = a.length;
			var startIdx = s != null ? (s < 0 ? len + s : s) : 0;
			var endIdx = en != null ? (en < 0 ? len + en : en) : len;

			if (startIdx < 0)
				startIdx = 0;
			if (endIdx > len)
				endIdx = len;
			if (startIdx > endIdx)
				return [];

			var result = [];
			if (st > 0) {
				var i = startIdx;
				while (i < endIdx) {
					result.push(a[i]);
					i += st;
				}
			} else if (st < 0) {
				var i = endIdx - 1;
				while (i >= startIdx) {
					result.push(a[i]);
					i += st;
				}
			}
			return result;
		} else if (Std.isOfType(arr, String)) {
			var str = cast(arr, String);
			var len = str.length;
			var startIdx = s != null ? (s < 0 ? len + s : s) : 0;
			var endIdx = en != null ? (en < 0 ? len + en : en) : len;

			if (startIdx < 0)
				startIdx = 0;
			if (endIdx > len)
				endIdx = len;
			if (startIdx > endIdx)
				return "";

			var result = "";
			if (st > 0) {
				var i = startIdx;
				while (i < endIdx) {
					result += str.charAt(i);
					i += st;
				}
			} else if (st < 0) {
				var i = endIdx - 1;
				while (i >= startIdx) {
					result += str.charAt(i);
					i += st;
				}
			}
			return result;
		}

		error(EKeyError("Slice operation not supported on this type"));
		return null;
	}

	private function handleImport(path:Array<String>, alias:String):Dynamic {
		var moduleName = path.join(".");
		var importName = alias != null ? alias : path[path.length - 1];

		// Try to load the module from variables (user-defined modules)
		var module = resolve(moduleName);

		if (module != null) {
			variables.set(importName, module);
			return null;
		}

		// If module not found, just warn but don't fail
		// This allows code to run even if imports are missing
		#if sys
		Sys.println("Warning: Module '" + moduleName + "' not found");
		#else
		trace("Warning: Module '" + moduleName + "' not found");
		#end

		return null;
	}

	private function handleImportFrom(path:Array<String>, items:Array<String>, alias:String):Dynamic {
		var moduleName = path.join(".");

		// Try to load the module
		var module = resolve(moduleName);

		if (module == null) {
			#if sys
			Sys.println("Warning: Module '" + moduleName + "' not found");
			#else
			trace("Warning: Module '" + moduleName + "' not found");
			#end
			return null;
		}

		// Handle 'from module import *'
		if (items.length == 1 && items[0] == "*") {
			if (Std.isOfType(module, haxe.ds.StringMap)) {
				var map = cast(module, haxe.ds.StringMap<Dynamic>);
				for (key in map.keys()) {
					variables.set(key, map.get(key));
				}
			}
			return null;
		}

		// Handle specific imports: 'from module import name1, name2'
		if (Std.isOfType(module, haxe.ds.StringMap)) {
			var map = cast(module, haxe.ds.StringMap<Dynamic>);
			for (item in items) {
				var value = map.get(item);
				if (value != null) {
					var importName = alias != null ? alias : item;
					variables.set(importName, value);
				} else {
					#if sys
					Sys.println("Warning: '" + item + "' not found in module '" + moduleName + "'");
					#else
					trace("Warning: '" + item + "' not found in module '" + moduleName + "'");
					#end
				}
			}
		}

		return null;
	}

	private function whileLoop(econd:Expr, e:Expr) {
		while (expr(econd) == true) {
			if (!loopRun(() -> expr(e)))
				break;
		}
	}

	private function makeIterator(v:Dynamic):Iterator<Dynamic> {
		#if js
		if (v is Array)
			return (v : Array<Dynamic>).iterator();
		if (v.iterator != null)
			v = v.iterator();
		#else
		try
			v = v.iterator()
		catch (e:Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}

	private function makeKeyValueIterator(v:Dynamic):KeyValueIterator<Dynamic, Dynamic> {
		#if js
		if (v is Array)
			return (v : Array<Dynamic>).keyValueIterator();
		if (v.keyValueIterator != null)
			v = v.keyValueIterator();
		#else
		try
			v = v.keyValueIterator()
		catch (e:Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}

	private function forLoop(n:String, it:Expr, e:Expr) {
		var old = declared.length;
		declared.push({n: n, old: locals.get(n)});
		var it = makeIterator(expr(it));
		while (it.hasNext()) {
			locals.set(n, {r: it.next()});
			if (!loopRun(() -> expr(e)))
				break;
		}
		restore(old);
	}

	private function forKeyValueLoop(vk:String, vv:String, it:Expr, e:Expr) {
		var old = declared.length;
		declared.push({n: vk, old: locals.get(vk)});
		declared.push({n: vv, old: locals.get(vv)});
		var it = makeKeyValueIterator(expr(it));
		while (it.hasNext()) {
			var v = it.next();
			locals.set(vk, {r: v.key});
			locals.set(vv, {r: v.value});
			if (!loopRun(() -> expr(e)))
				break;
		}
		restore(old);
	}

	private inline function loopRun(f:Void->Void):Bool {
		var cont = true;
		try {
			f();
		} catch (err:Stop) {
			switch (err) {
				case SContinue:
				case SBreak:
					cont = false;
				case SReturn:
					throw err;
			}
		}
		return cont;
	}

	private inline function isMap(o:Dynamic):Bool {
		return (o is IMap);
	}

	private inline function getMapValue(map:Dynamic, key:Dynamic):Dynamic {
		return cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).get(key);
	}

	private inline function setMapValue(map:Dynamic, key:Dynamic, value:Dynamic):Void {
		cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).set(key, value);
	}

	private function makeMap(keys:Array<Dynamic>, values:Array<Dynamic>):Dynamic {
		var isAllString = true;
		var isAllInt = true;
		var isAllObject = true;
		var isAllEnum = true;

		for (key in keys) {
			isAllString = isAllString && (key is String);
			isAllInt = isAllInt && (key is Int);
			isAllObject = isAllObject && Reflect.isObject(key);
			isAllEnum = isAllEnum && Reflect.isEnumValue(key);
		}

		if (isAllInt) {
			var m = new Map<Int, Dynamic>();
			for (i => key in keys)
				m.set(key, values[i]);
			return m;
		}
		if (isAllString) {
			var m = new Map<String, Dynamic>();
			for (i => key in keys)
				m.set(key, values[i]);
			return m;
		}
		if (isAllEnum) {
			var m = new haxe.ds.EnumValueMap<Dynamic, Dynamic>();
			for (i => key in keys)
				m.set(key, values[i]);
			return m;
		}
		if (isAllObject) {
			var m = new Map<{}, Dynamic>();
			for (i => key in keys)
				m.set(key, values[i]);
			return m;
		}
		error(EKeyError("Invalid map keys " + keys));
		return null;
	}

	public function get(o:Dynamic, f:String):Dynamic {
		if (o == null)
			error(EInvalidAccess(f));
		return {
			#if php
			try {
				Reflect.getProperty(o, f);
			} catch (e:Dynamic) {
				Reflect.field(o, f);
			}
			#else
			Reflect.getProperty(o, f);
			#end
		}
	}

	public function set(o:Dynamic, f:String, v:Dynamic):Dynamic {
		if (o == null)
			error(EInvalidAccess(f));
		Reflect.setProperty(o, f, v);
		return v;
	}

	private function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic {
		return call(o, get(o, f), args);
	}

	private function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic {
		return Reflect.callMethod(o, f, args);
	}

	private function cnew(cl:String, args:Array<Dynamic>):Dynamic {
		if (!allowClassResolve)
			error(EClassNotAllowed("Class instantiation is disabled"));

		var c = Type.resolveClass(cl);
		if (c == null)
			c = resolve(cl);
		return Type.createInstance(c, args);
	}

	private function isTruthy(v:Dynamic):Bool {
		if (v == null || v == false)
			return false;
		if (v == 0 || v == "")
			return false;
		return true;
	}
}
