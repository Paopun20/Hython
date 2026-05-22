package paopao.hython;

import haxe.Constraints;
import haxe.PosInfos;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import paopao.hython.utils.UnsafeReflect as Reflect;
import paopao.hython.Semantic;
import paopao.hython.Ast;
import paopao.hython.Error;
import paopao.hython.PyData;
import haxe.exceptions.NotImplementedException;

private enum Flow {
	FNone;
	FReturn(value:PyValue);
	FBreak;
	FContinue;
}

// Simple Interpreter AST Walker
@:nullSafety(Strict)
class Interpreter {
	public var filename(get, null):String = "";
	var _filename = "";
	inline function get_filename()
		return _filename;

	var globals: StringMap<PyValue>;
	var frames:Array<StringMap<PyValue>>;
	var functionDepth:Int;

	public static var maxCallDepth = 1000;

	public function new(filename:String) {
		this._filename = filename;
		this.globals = new StringMap<PyValue>();
		this.frames = [globals];
		this.functionDepth = 0;
	}

	/*
		find in root or class
	*/
	private function findMethods(body: Stmt, name:String): Null<Stmt> {
		return switch (body) {
			case SClassDef(_, _, classBody):
				var found:Null<Stmt> = null;
				for (stmt in classBody) {
					var matches = switch (stmt) {
						case SFunctionDef(methodName, _, _, _, _): methodName == name;
						default: false;
					};
					if (matches) {
						found = stmt;
						break;
					}
				}
				found;
			default:
				null;
		}
	}

	private function runBody(body: Stmt, args:Null<Array<PyValue>>):Flow {
		var isRootMode = functionDepth == 0;
		return switch (body) {
			case SExpr(value):
				evalExpr(value);
				FNone;

			case SAssign(targets, value):
				var resolved = evalExpr(value);
				for (target in targets)
					assignTarget(target, resolved);
				FNone;

			case SReturn(value):
				if (isRootMode)
					runtimeError(TypeError("'return' outside function"), body);
				FReturn(value == null ? VNone : evalExpr(value));

			case SIf(test, ifBody, orelse):
				runBlock(isTruthy(evalExpr(test)) ? ifBody : orelse, false);

			case SWhile(test, whileBody, orelse):
				var completed = true;
				while (isTruthy(evalExpr(test))) {
					switch (runBlock(whileBody, false)) {
						case FNone:
						case FContinue:
							continue;
						case FBreak:
							completed = false;
							break;
						case FReturn(value):
							return FReturn(value);
					}
				}
				if (completed)
					return runBlock(orelse, false);
				FNone;

			case SFor(target, iter, forBody, orelse, _):
				var completed = true;
				for (item in iterableValues(evalExpr(iter), body)) {
					assignTarget(target, item);
					switch (runBlock(forBody, false)) {
						case FNone:
						case FContinue:
							continue;
						case FBreak:
							completed = false;
							break;
						case FReturn(value):
							return FReturn(value);
					}
				}
				if (completed)
					return runBlock(orelse, false);
				FNone;

			case SBreak:
				FBreak;

			case SContinue:
				FContinue;

			case SPass:
				FNone;

			case SFunctionDef(name, arguments, functionBody, _, _):
				var params = new Vector<String>(arguments.args.length);
				for (i in 0...arguments.args.length)
					params[i] = arguments.args[i].name;
				currentFrame().set(name, VFunction(FUser(name, params, Vector.fromArrayCopy(functionBody))));
				FNone;

			case SClassDef(name, bases, classBody):
				var methods = new StringMap<PyValue>();
				var fields = new StringMap<PyValue>();
				for (stmt in classBody) {
					switch (stmt) {
						case SFunctionDef(methodName, arguments, methodBody, _, _):
							var params = new Vector<String>(arguments.args.length);
							for (i in 0...arguments.args.length)
								params[i] = arguments.args[i].name;
							methods.set(methodName, VFunction(FUser(methodName, params, Vector.fromArrayCopy(methodBody))));
						case SAssign(targets, value):
							var resolved = evalExpr(value);
							for (target in targets) {
								switch (target) {
									case EName(fieldName):
										fields.set(fieldName, resolved);
									default:
										runtimeError(TypeError("invalid class assignment target"), stmt);
								}
							}
						default:
					}
				}
				currentFrame().set(name, VClass(FUser(name, bases.map(evalExpr), methods, fields)));
				FNone;

			case STry(_, _, _, _):
				runtimeError(CustomError("try/except is not implemented"), body);

			case SImport(_) | SImportFrom(_, _):
				runtimeError(ImportError("imports are not implemented"), body);
		}
	}

	public function callDef(funcName:String, args:Array<PyValue>): PyValue {
		var value = resolveName(funcName, null);
		return switch (value) {
			case VFunction(func):
				callFunction(func, args);
			default:
				throw new Error(TypeError(funcName + " is not callable"), 0, 0, filename);
		}
	}

	public function run(source:String, skipChacking:Bool = false) {
		var code:Module = Interpreter.compile(source, filename, skipChacking);
		switch (runBlock(code.body, false)) {
			case FNone:
			case FReturn(_):
				throw new Error(SyntaxError("'return' outside function"), 0, 0, filename);
			case FBreak:
				throw new Error(SyntaxError("'break' outside loop"), 0, 0, filename);
			case FContinue:
				throw new Error(SyntaxError("'continue' outside loop"), 0, 0, filename);
		}
	}

	private function runBlock(body:Array<Stmt>, newFrame:Bool):Flow {
		if (newFrame)
			frames.push(new StringMap<PyValue>());

		for (stmt in body) {
			var flow = runBody(stmt, newFrame ? [] : null);
			switch (flow) {
				case FNone:
				default:
					if (newFrame)
						frames.pop();
					return flow;
			}
		}

		if (newFrame)
			frames.pop();
		return FNone;
	}

	private inline function currentFrame():StringMap<PyValue> {
		return frames[frames.length - 1];
	}

	private function resolveName(name:String, node:Null<Dynamic>):PyValue {
		var i = frames.length - 1;
		while (i >= 0) {
			var frame = frames[i];
			if (frame.exists(name)) {
				var value = frame.get(name);
				if (value != null)
					return value;
			}
			i--;
		}

		return switch (name) {
			case "True": VBool(true);
			case "False": VBool(false);
			case "None": VNone;
			default:
				throw positionedError(NameError("name '" + name + "' is not defined"), node);
		}
	}

	private function evalExpr(expr:Expr):PyValue {
		return switch (expr) {
			case EName(id):
				resolveName(id, expr);

			case EConstant(value):
				constToValue(value);

			case EBinOp(left, op, right):
				evalBinOp(evalExpr(left), op, evalExpr(right), expr);

			case EUnaryOp(op, operand):
				evalUnaryOp(op, evalExpr(operand), expr);

			case ECall(func, argExprs):
				var callee = evalExpr(func);
				var args = argExprs.map(evalExpr);
				switch (callee) {
					case VFunction(func):
						callFunction(func, args);
					case VClass(classDef):
						instantiateClass(classDef, args);
					default:
						runtimeError(TypeError("object is not callable"), expr);
				}

			case EAttribute(value, attr):
				getAttribute(evalExpr(value), attr, expr);

			case ESubscript(value, slice):
				getSubscript(evalExpr(value), evalExpr(slice), expr);

			case EList(elts):
				VList(elts.map(evalExpr));

			case ETuple(elts):
				VTuple(elts.map(evalExpr));

			case EDict(keys, values):
				var map = new StringMap<PyValue>();
				for (i in 0...keys.length)
					map.set(valueKey(evalExpr(keys[i])), evalExpr(values[i]));
				VDict(map);

			case EIfExp(test, body, orelse):
				isTruthy(evalExpr(test)) ? evalExpr(body) : evalExpr(orelse);

			case ELambda(_, _):
				runtimeError(CustomError("lambda is not implemented"), expr);

			case EAwait(_) | EYield(_):
				runtimeError(CustomError("async/generator expressions are not implemented"), expr);
		}
	}

	private function callFunction(func:PyFunction, args:Array<PyValue>):PyValue {
		return switch (func) {
			case FNative(_, _, onCall):
				onCall(Vector.fromArrayCopy(args));

			case FUser(name, params, body):
				if (args.length != params.length)
					throw new Error(TypeError(name + "() expected " + params.length + " arguments, got " + args.length), 0, 0, filename);

				var frame = new StringMap<PyValue>();
				for (i in 0...params.length)
					frame.set(params[i], args[i]);

				frames.push(frame);
				functionDepth++;
				var flow = FNone;
				try {
					for (stmt in body) {
						flow = runBody(stmt, args);
						switch (flow) {
							case FNone:
							default:
								break;
						}
					}
				} catch (e:Dynamic) {
					functionDepth--;
					frames.pop();
					throw e;
				}
				functionDepth--;
				frames.pop();
				return switch (flow) {
					case FNone:
						VNone;
					case FReturn(value):
						value;
					case FBreak:
						throw new Error(SyntaxError("'break' outside loop"), 0, 0, filename);
					case FContinue:
						throw new Error(SyntaxError("'continue' outside loop"), 0, 0, filename);
				}
		}
	}

	public function getGlobal(key: String): Null<PyValue> {
		return globals.get(key);
	}

	public function setGlobal(key: String, value: PyValue): Void {
		globals.set(key, value);
	}

	public static function haxeToPyValue(value:Dynamic):PyValue {
		if (value == null)
			return VNone;

		switch (Type.typeof(value)) {
			case TEnum(enumType):
				if (enumType == PyValue)
					return cast value;
			default:
		}

		if (Std.isOfType(value, Array)) {
			var source:Array<Dynamic> = cast value;
			return VList([for (item in source) haxeToPyValue(item)]);
		}

		if (Std.isOfType(value, StringMap)) {
			var source:StringMap<Dynamic> = cast value;
			var map = new StringMap<PyValue>();
			for (key in source.keys())
				map.set(key, haxeToPyValue(source.get(key)));
			return VDict(map);
		}

		if (Reflect.isFunction(value)) {
			var params = new Vector<String>(0);
			return VFunction(FNative("native", params, function(args:Vector<PyValue>):PyValue {
				var haxeArgs:Array<Dynamic> = [];
				for (arg in args)
					haxeArgs.push(pyValueToHaxe(arg));
				return haxeToPyValue(Reflect.callMethod(null, cast value, haxeArgs));
			}));
		}

		return switch (Type.typeof(value)) {
			case TBool:
				VBool(cast value);
			case TInt:
				VInt(cast value);
			case TFloat:
				VFloat(cast value);
			case TClass(String):
				VString(cast value);
			case TObject:
				var map = new StringMap<PyValue>();
				for (field in Reflect.fields(value))
					map.set(field, haxeToPyValue(Reflect.field(value, field)));
				VDict(map);
			default:
				throw new Error(TypeError("cannot convert Haxe value to PyValue: " + Std.string(value)), 0, 0, "<haxe>");
		}
	}

	public static function pyValueToHaxe(value:PyValue):Dynamic {
		return switch (value) {
			case VInt(v):
				v;
			case VFloat(v):
				v;
			case VString(v):
				v;
			case VBool(v):
				v;
			case VNone:
				null;
			case VList(items) | VTuple(items):
				[for (item in items) pyValueToHaxe(item)];
			case VDict(map):
				var result = new StringMap<Dynamic>();
				for (key in map.keys()) {
					var item = map.get(key);
					if (item != null)
						result.set(key, pyValueToHaxe(item));
				}
				result;
			case VFunction(FNative(_, _, onCall)):
				Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic {
					var pyArgs = new Vector<PyValue>(args.length);
					for (i in 0...args.length)
						pyArgs[i] = haxeToPyValue(args[i]);
					return pyValueToHaxe(onCall(pyArgs));
				});
			case VFunction(_) | VClass(_) | VInstance(_):
				value;
		}
	}

	private function instantiateClass(classDef:PyClass, args:Array<PyValue>):PyValue {
		var fields = new StringMap<PyValue>();
		switch (classDef) {
			case FUser(_, _, _, classFields) | FNative(_, _, classFields):
				for (key in classFields.keys()) {
					var value = classFields.get(key);
					if (value != null)
						fields.set(key, value);
				}
		}
		return VInstance(classDef, fields);
	}

	private function assignTarget(target:Expr, value:PyValue):Void {
		switch (target) {
			case EName(id):
				currentFrame().set(id, value);

			case ESubscript(containerExpr, indexExpr):
				var container = evalExpr(containerExpr);
				var index = evalExpr(indexExpr);
				switch (container) {
					case VList(items):
						var i = intIndex(index, target);
						if (i < 0 || i >= items.length)
							runtimeError(IndexError("list index out of range"), target);
						items[i] = value;
					case VDict(map):
						map.set(valueKey(index), value);
					default:
						runtimeError(TypeError("object does not support item assignment"), target);
				}

			case EAttribute(objectExpr, attr):
				switch (evalExpr(objectExpr)) {
					case VInstance(_, fields):
						fields.set(attr, value);
					default:
						runtimeError(AttributeError("can't set attribute"), target);
				}

			default:
				runtimeError(TypeError("invalid assignment target"), target);
		}
	}

	private function evalBinOp(left:PyValue, op:BinOp, right:PyValue, node:Expr):PyValue {
		return switch (op) {
			case Add:
				switch [left, right] {
					case [VInt(a), VInt(b)]: VInt(a + b);
					case [VFloat(a), VFloat(b)]: VFloat(a + b);
					case [VInt(a), VFloat(b)]: VFloat(a + b);
					case [VFloat(a), VInt(b)]: VFloat(a + b);
					case [VString(a), VString(b)]: VString(a + b);
					default: runtimeError(TypeError("unsupported operand type(s) for +"), node);
				}
			case Sub:
				numeric(left, right, function(a, b) return a - b, function(a, b) return a - b, node);
			case Mult:
				numeric(left, right, function(a, b) return a * b, function(a, b) return a * b, node);
			case Div:
				switch (right) {
					case VInt(0) | VFloat(0):
						runtimeError(ZeroDivisionError, node);
					default:
				}
				numeric(left, right, function(a, b) return a / b, function(a, b) return a / b, node, true);
			case Mod:
				switch (right) {
					case VInt(0) | VFloat(0):
						runtimeError(ZeroDivisionError, node);
					default:
				}
				numeric(left, right, function(a, b) return a % b, function(a, b) return a % b, node);
			case Eq:
				VBool(valueEquals(left, right));
			case NotEq:
				VBool(!valueEquals(left, right));
			case Lt:
				compare(left, right, function(a, b) return a < b, node);
			case Gt:
				compare(left, right, function(a, b) return a > b, node);
			case LtE:
				compare(left, right, function(a, b) return a <= b, node);
			case GtE:
				compare(left, right, function(a, b) return a >= b, node);
			case And:
				VBool(isTruthy(left) && isTruthy(right));
			case Or:
				VBool(isTruthy(left) || isTruthy(right));
		}
	}

	private function evalUnaryOp(op:UnaryOp, value:PyValue, node:Expr):PyValue {
		return switch (op) {
			case Not:
				VBool(!isTruthy(value));
			case UAdd:
				switch (value) {
					case VInt(_) | VFloat(_): value;
					default: runtimeError(TypeError("bad operand type for unary +"), node);
				}
			case USub:
				switch (value) {
					case VInt(v): VInt(-v);
					case VFloat(v): VFloat(-v);
					default: runtimeError(TypeError("bad operand type for unary -"), node);
				}
			case Invert:
				switch (value) {
					case VInt(v): VInt(~v);
					default: runtimeError(TypeError("bad operand type for unary ~"), node);
				}
		}
	}

	private function numeric(left:PyValue, right:PyValue, intOp:Int->Int->Dynamic, floatOp:Float->Float->Float, node:Expr, forceFloat:Bool = false):PyValue {
		return switch [left, right] {
			case [VInt(a), VInt(b)]:
				forceFloat ? VFloat(floatOp(a, b)) : VInt(intOp(a, b));
			case [VFloat(a), VFloat(b)]:
				VFloat(floatOp(a, b));
			case [VInt(a), VFloat(b)]:
				VFloat(floatOp(a, b));
			case [VFloat(a), VInt(b)]:
				VFloat(floatOp(a, b));
			default:
				runtimeError(TypeError("unsupported operand type(s)"), node);
		}
	}

	private function compare(left:PyValue, right:PyValue, op:Float->Float->Bool, node:Expr):PyValue {
		return switch [left, right] {
			case [VInt(a), VInt(b)]: VBool(op(a, b));
			case [VFloat(a), VFloat(b)]: VBool(op(a, b));
			case [VInt(a), VFloat(b)]: VBool(op(a, b));
			case [VFloat(a), VInt(b)]: VBool(op(a, b));
			case [VString(a), VString(b)]: VBool(opString(a, b, op));
			default: runtimeError(TypeError("unsupported comparison"), node);
		}
	}

	private function opString(a:String, b:String, op:Float->Float->Bool):Bool {
		return op(Reflect.compare(a, b), 0);
	}

	private function getAttribute(value:PyValue, attr:String, node:Expr):PyValue {
		return switch (value) {
			case VInstance(cls, fields):
				if (fields.exists(attr))
					fields.get(attr);
				else switch (cls) {
					case FUser(_, _, methods, _) | FNative(_, methods, _):
						if (methods.exists(attr))
							methods.get(attr);
						else
							runtimeError(AttributeError("object has no attribute '" + attr + "'"), node);
				}
			case VClass(FUser(_, _, methods, fields)) | VClass(FNative(_, methods, fields)):
				if (fields.exists(attr))
					fields.get(attr);
				else if (methods.exists(attr))
					methods.get(attr);
				else
					runtimeError(AttributeError("class has no attribute '" + attr + "'"), node);
			default:
				runtimeError(AttributeError("object has no attribute '" + attr + "'"), node);
		}
	}

	private function getSubscript(value:PyValue, index:PyValue, node:Expr):PyValue {
		return switch (value) {
			case VList(items) | VTuple(items):
				var i = intIndex(index, node);
				if (i < 0 || i >= items.length)
					runtimeError(IndexError("index out of range"), node);
				items[i];
			case VString(text):
				var i = intIndex(index, node);
				if (i < 0 || i >= text.length)
					runtimeError(IndexError("string index out of range"), node);
				VString(text.charAt(i));
			case VDict(map):
				var key = valueKey(index);
				if (!map.exists(key))
					runtimeError(KeyError(key), node);
				map.get(key);
			default:
				runtimeError(TypeError("object is not subscriptable"), node);
		}
	}

	private function iterableValues(value:PyValue, node:Stmt):Array<PyValue> {
		return switch (value) {
			case VList(items) | VTuple(items):
				items;
			case VString(text):
				[for (i in 0...text.length) VString(text.charAt(i))];
			default:
				runtimeError(TypeError("object is not iterable"), node);
		}
	}

	private function intIndex(value:PyValue, node:Dynamic):Int {
		return switch (value) {
			case VInt(i): i;
			default: throw positionedError(TypeError("index must be int"), node);
		}
	}

	private function constToValue(value:ConstValue):PyValue {
		return switch (value) {
			case CInt(v): VInt(v);
			case CFloat(v): VFloat(v);
			case CString(v): VString(v);
			case CBool(v): VBool(v);
			case CNone: VNone;
			case VObject(_) | VFunction(_):
				throw new Error(CustomError("constant bridge values are not supported by the interpreter"), 0, 0, filename);
		}
	}

	private function isTruthy(value:PyValue):Bool {
		return switch (value) {
			case VNone: false;
			case VBool(v): v;
			case VInt(v): v != 0;
			case VFloat(v): v != 0;
			case VString(v): v.length > 0;
			case VList(items) | VTuple(items): items.length > 0;
			case VDict(map):
				map.keys().hasNext();
			default:
				true;
		}
	}

	private function valueEquals(left:PyValue, right:PyValue):Bool {
		return switch [left, right] {
			case [VNone, VNone]: true;
			case [VBool(a), VBool(b)]: a == b;
			case [VInt(a), VInt(b)]: a == b;
			case [VFloat(a), VFloat(b)]: a == b;
			case [VInt(a), VFloat(b)]: a == b;
			case [VFloat(a), VInt(b)]: a == b;
			case [VString(a), VString(b)]: a == b;
			default: false;
		}
	}

	private function valueKey(value:PyValue):String {
		return switch (value) {
			case VString(v): v;
			case VInt(v): Std.string(v);
			case VFloat(v): Std.string(v);
			case VBool(v): Std.string(v);
			case VNone: "None";
			default: Std.string(value);
		}
	}

	private function runtimeError(error:ErrorDef, node:Dynamic):Dynamic {
		throw positionedError(error, node);
	}

	private function positionedError(error:ErrorDef, node:Null<Dynamic>):Error {
		var pos:Null<SourcePos> = null;
		if (node != null) {
			pos = NodeMeta.getStmtPos(cast node);
			if (pos == null)
				pos = NodeMeta.getExprPos(cast node);
		}
		return new Error(error, pos != null ? pos.line : 0, pos != null ? pos.col : 0, filename);
	}

	

	/**
	 * Instantiates a script class and calls its constructor with the given args.
	 * args are Haxe-side values — they'll be converted to script Values automatically.
	 */
	public function instantiate(name:String, args:Array<Dynamic>):Class<Dynamic> {
		throw new NotImplementedException();
	}

	public static function compile(source:String, ?filename:String, skipChacking:Bool = false):Module {
		var lexer = new Lexer(source);
		var ast = lexer.tokenize();

		var code = new Parser(ast, lexer.tokenPositions).parse();

		if (!skipChacking)
			Semantic.analyze(code, filename != null ? filename : "<inline>");

		return code;
	}
}
