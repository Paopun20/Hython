// This file implements the Hython bytecode VM — a stack-based execution engine
// that interprets CodeObjects emitted by the Compiler.
//
// Key features:
//  • Stack-based operand evaluation (all instructions read from and write to the stack).
//  • Call frames for nested function calls, each with its own local scope.
//  • Global scope accessible from Haxe via get/setGlobal() ("hooks").
//  • Type conversion between Python (Value) and Haxe (Dynamic).
//  • Haxe function/object wrapping — callable from Python with automatic arg conversion.
//  • Exception handling (try/except/finally) via Haxe's throw/catch.
//  • Basic introspection via reflection for calling Python functions from Haxe.
package paopao.hython;

import paopao.hython.Ast;
import paopao.hython.Bytecode;
import paopao.hython.Error;
import haxe.Constraints;
import haxe.ds.StringMap;
import haxe.PosInfos;
import paopao.hython.data.VMValue;
import paopao.hython.utils.UnsafeReflect as Reflect;

// Stack frame — one activation record per function call.
private typedef Frame = {
	code:CodeObject,
	pc:Int, // program counter (current instruction index)
	locals:StringMap<Value>, // Local variable bindings
	stack:Array<Value>, // Value stack for this frame
}

// Exception handler entry
private typedef ExceptionHandler = {
	label:Int,
	startPc:Int,
	endPc:Int,
}

@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class VM {
	// Global scope (module-level variables, hookable from Haxe).
	private var globals:StringMap<Value>;

	// Call stack — frames for nested function calls.
	private var frames:Array<Frame>;

	// Current frame (convenience pointer; same as frames[frames.length-1]).
	private var frame:Frame;

	// Exception/finally block stack (for SETUP_EXCEPT, SETUP_FINALLY).
	private var blockStack:Array<Int>;

	// Built-in functions and types (int, str, len, print, range, etc.)
	private var builtins:StringMap<Value>;

	// Guard against unbounded recursion causing host runtime stack overflow.
	private var maxCallDepth:Int;

	public function new() {
		this.globals = new StringMap();
		this.frames = [];
		this.blockStack = [];
		this.builtins = new StringMap();
		// Keep the recursion guard conservative on C++ targets to avoid
		// exhausting the native call stack before the VM can raise RecursionError.
		this.maxCallDepth = #if cpp 32 #else 1000 #end;

		initBuiltins();
	}

	// Execute a CodeObject in the global scope and return the final value.
	public function execute(code:CodeObject):Value {
		// Create the initial frame (module/global scope).
		pushFrame(code, globals);

		// Main execution loop: fetch-decode-execute.
		while (frames.length > 0) {
			if (frame.pc >= frame.code.instructions.length)
				break; // End of code

			var instr = frame.code.instructions[frame.pc];
			frame.pc++;

			executeInstruction(instr);
		}

		// Module should leave the final value on the stack.
		return frame != null && frame.stack.length > 0 ? frame.stack[frame.stack.length - 1] : VNone;
	}

	private function executeInstruction(instr:OpCode):Void {
		switch (instr) {
			case NOP:
				// No operation

			case POP_TOP:
				pop();

			case DUP_TOP:
				var v = peek();
				push(v);

			case ROT_TWO:
				var tos = pop();
				var tos1 = pop();
				push(tos);
				push(tos1);

			case ROT_THREE:
				var tos = pop();
				var tos1 = pop();
				var tos2 = pop();
				push(tos);
				push(tos2);
				push(tos1);

			case LOAD_CONST(c):
				push(valueFromConst(c));

			case LOAD_NAME(name):
				var v = lookupName(name);
				push(v);

			case STORE_NAME(name):
				var v = pop();
				// At module scope, names should be visible as globals so
				// host code can fetch them via getGlobal().
				if (frame.code.name == "<module>")
					globals.set(name, v);
				else
					frame.locals.set(name, v);

			case LOAD_FAST(name):
				if (!frame.locals.exists(name))
					throw new Error(NameError('undefined variable: ${name}'), 0, 0);
				push(frame.locals.get(name));

			case STORE_FAST(name):
				var v = pop();
				frame.locals.set(name, v);

			case LOAD_GLOBAL(name):
				if (!globals.exists(name))
					throw new Error(NameError('undefined variable: ${name}'), 0, 0);
				push(globals.get(name));

			case STORE_GLOBAL(name):
				var v = pop();
				globals.set(name, v);

			case LOAD_ATTR(attr):
				var obj = pop();
				var v = getAttr(obj, attr);
				push(v);

			case STORE_ATTR(attr):
				var value = pop();
				var obj = pop();
				setAttr(obj, attr, value);

			case BINARY_SUBSCR:
				var idx = pop();
				var obj = pop();
				var v = getSubscript(obj, idx);
				push(v);

			case STORE_SUBSCR:
				var idx = pop();
				var obj = pop();
				var value = pop();
				setSubscript(obj, idx, value);

			case BINARY_OP(op):
				var right = pop();
				var left = pop();
				var result = evalBinOp(left, op, right);
				push(result);

			case UNARY_OP(op):
				var operand = pop();
				var result = evalUnaryOp(op, operand);
				push(result);

			case BUILD_LIST(count):
				var items = popN(count);
				push(VList(items));

			case BUILD_TUPLE(count):
				var items = popN(count);
				push(VTuple(items));

			case BUILD_DICT(count):
				var map = new StringMap<Value>();
				for (_ in 0...count) {
					var value = pop();
					var key = pop();
					var keyStr = valueToString(key);
					map.set(keyStr, value);
				}
				push(VDict(map));

			case UNPACK_SEQUENCE(count):
				var val = pop();
				var items = switch (val) {
					case VList(items): items;
					case VTuple(items): items;
					default: throw new Error(TypeError('cannot unpack non-sequence'), 0, 0);
				}
				// Push items in reverse order so they unpack correctly without
				// mutating the original sequence object.
				for (i in 0...items.length) {
					push(items[items.length - 1 - i]);
				}

			case MAKE_FUNCTION(code):
				var func = VFunction({code: code, globals: frame.locals}); // closure
				push(func);

			case CALL_FUNCTION(argc):
				var args = popN(argc);
				var func = pop();
				var result = callFunction(func, args);
				push(result);

			case RETURN_VALUE:
				var retval = pop();
				// Save caller's stack reference before popping
				var callerStack = (frames.length > 1) ? frames[frames.length - 2].stack : null;
				// Push to caller's stack first (if exists) or current frame
				if (callerStack != null) {
					callerStack.push(retval);
				} else {
					push(retval);
				}
				// Then pop the frame
				popFrame();

			case GET_ITER:
				var obj = pop();
				var iter = toIterator(obj);
				push(iter);

			case FOR_ITER(label):
				var iter = peek(); // don't pop yet
				var next_val = iteratorNext(iter);
				if (next_val == null) {
					// StopIteration — jump to label
					pop(); // discard the iterator
					frame.pc = label;
				} else {
					// Push the next value (iterator stays on stack)
					push(next_val);
				}

			case JUMP_ABSOLUTE(label) | JUMP_FORWARD(label):
				frame.pc = label;

			case POP_JUMP_IF_FALSE(label):
				var v = pop();
				if (!isTruthy(v))
					frame.pc = label;

			case POP_JUMP_IF_TRUE(label):
				var v = pop();
				if (isTruthy(v))
					frame.pc = label;

			case SETUP_LOOP(afterLabel):
				blockStack.push(afterLabel);

			case POP_BLOCK:
				if (blockStack.length > 0)
					blockStack.pop();

			case BREAK_LOOP:
				if (blockStack.length > 0) {
					var target = blockStack.pop();
					frame.pc = target;
				}

			case CONTINUE_LOOP(loopStart):
				frame.pc = loopStart;

			case SETUP_EXCEPT(handlerLabel):
				blockStack.push(handlerLabel);

			case SETUP_FINALLY(finallyLabel):
				blockStack.push(finallyLabel);

			case END_FINALLY:
				// In a full implementation, this would unwind exception state.
				// For now, it's a placeholder.
				pass();

			case IMPORT_NAME(name):
				// Simplified: push a dummy module object.
				var mod = VNativeObject(name, {});
				push(mod);

			case IMPORT_FROM(attr):
				var mod = pop();
				// Extract attribute from module; push it.
				var v = getAttr(mod, attr);
				push(v);

			case BUILD_CLASS(baseCount):
				var bases = popN(baseCount);
				var body_fn = pop();
				var name_str = pop();

				var className = valueToString(name_str);

				// Call the body function to build the class dict.
				var classDict = callFunction(body_fn, []);

				var classDef:ClassDef = {
					name: className,
					bases: bases,
					methods: new StringMap(),
					fields: switch (classDict) {
						case VDict(map): map;
						default: new StringMap();
					}
				}

				push(VClass(classDef));

			case YIELD_VALUE:
				// Placeholder for generator support
				var v = pop();
				push(v);

			case GET_AWAITABLE:
				// Placeholder for async support
				var v = pop();
				push(v);

			case LABEL(_):
				// Should never execute (labels are removed by resolveLabels)
				throw new Error(SyntaxError("internal: LABEL reached"), 0, 0);
		}
	}

	private function evalBinOp(left:Value, op:BinOp, right:Value):Value {
		return switch (op) {
			case Add: binOpAdd(left, right);
			case Sub: binOpSub(left, right);
			case Mult: binOpMult(left, right);
			case Div: binOpDiv(left, right);
			case Mod: binOpMod(left, right);
			case Eq: VBool(valuesEqual(left, right));
			case NotEq: VBool(!valuesEqual(left, right));
			case Lt: VBool(binOpLt(left, right));
			case Gt: VBool(binOpGt(left, right));
			case LtE: VBool(!binOpGt(left, right));
			case GtE: VBool(!binOpLt(left, right));
			case And: isTruthy(left) ? right : left;
			case Or: isTruthy(left) ? left : right;
		}
	}

	private function binOpAdd(l:Value, r:Value):Value {
		return switch ([l, r]) {
			case [VInt(a), VInt(b)]: VInt(a + b);
			case [VFloat(a), VFloat(b)]: VFloat(a + b);
			case [VInt(a), VFloat(b)]: VFloat(a + b);
			case [VFloat(a), VInt(b)]: VFloat(a + b);
			case [VString(a), VString(b)]: VString(a + b);
			case [VList(a), VList(b)]: VList(a.concat(b));
			default: throw new Error(TypeError('unsupported operand types for +'), 0, 0);
		}
	}

	private function binOpSub(l:Value, r:Value):Value {
		return switch ([l, r]) {
			case [VInt(a), VInt(b)]: VInt(a - b);
			case [VFloat(a), VFloat(b)]: VFloat(a - b);
			case [VInt(a), VFloat(b)]: VFloat(a - b);
			case [VFloat(a), VInt(b)]: VFloat(a - b);
			default: throw new Error(TypeError('unsupported operand types for -'), 0, 0);
		}
	}

	function repeat(s:String, n:Int):String {
		var buf = new StringBuf();
		for (i in 0...n)
			buf.add(s);
		return buf.toString();
	}

	private function binOpMult(l:Value, r:Value):Value {
		return switch ([l, r]) {
			case [VInt(a), VInt(b)]: VInt(a * b);
			case [VFloat(a), VFloat(b)]: VFloat(a * b);
			case [VInt(a), VFloat(b)]: VFloat(a * b);
			case [VFloat(a), VInt(b)]: VFloat(a * b);
			case [VString(s), VInt(n)] | [VInt(n), VString(s)]: VString(repeat(s, n));
			default: throw new Error(TypeError('unsupported operand types for *'), 0, 0);
		}
	}

	private function binOpDiv(l:Value, r:Value):Value {
		return switch ([l, r]) {
			case [VInt(a), VInt(b)]:
				if (b == 0)
					throw new Error(ZeroDivisionError, 0, 0);
				VFloat(a / b);
			case [VFloat(a), VFloat(b)]:
				if (b == 0.0)
					throw new Error(ZeroDivisionError, 0, 0);
				VFloat(a / b);
			case [VInt(a), VFloat(b)]:
				if (b == 0.0)
					throw new Error(ZeroDivisionError, 0, 0);
				VFloat(a / b);
			case [VFloat(a), VInt(b)]:
				if (b == 0)
					throw new Error(ZeroDivisionError, 0, 0);
				VFloat(a / b);
			default: throw new Error(TypeError('unsupported operand types for /'), 0, 0);
		}
	}

	private function binOpMod(l:Value, r:Value):Value {
		return switch ([l, r]) {
			case [VInt(a), VInt(b)]:
				if (b == 0)
					throw new Error(ZeroDivisionError, 0, 0);
				VInt(a % b);
			default: throw new Error(TypeError('unsupported operand types for %'), 0, 0);
		}
	}

	private function binOpLt(l:Value, r:Value):Bool {
		return switch ([l, r]) {
			case [VInt(a), VInt(b)]: a < b;
			case [VFloat(a), VFloat(b)]: a < b;
			case [VInt(a), VFloat(b)]: a < b;
			case [VFloat(a), VInt(b)]: a < b;
			case [VString(a), VString(b)]: a < b;
			default: throw new Error(TypeError('unorderable types'), 0, 0);
		}
	}

	private function binOpGt(l:Value, r:Value):Bool {
		return switch ([l, r]) {
			case [VInt(a), VInt(b)]: a > b;
			case [VFloat(a), VFloat(b)]: a > b;
			case [VInt(a), VFloat(b)]: a > b;
			case [VFloat(a), VInt(b)]: a > b;
			case [VString(a), VString(b)]: a > b;
			default: throw new Error(TypeError('unorderable types'), 0, 0);
		}
	}

	private function evalUnaryOp(op:UnaryOp, operand:Value):Value {
		return switch (op) {
			case Not: VBool(!isTruthy(operand));
			case USub: switch (operand) {
					case VInt(v): VInt(-v);
					case VFloat(v): VFloat(-v);
					default: throw new Error(TypeError('bad operand type for unary -'), 0, 0);
				}
			case UAdd: switch (operand) {
					case VInt(v): VInt(v);
					case VFloat(v): VFloat(v);
					default: throw new Error(TypeError('bad operand type for unary +'), 0, 0);
				}
			case Invert: switch (operand) {
					case VInt(v): VInt(~v);
					default: throw new Error(TypeError('bad operand type for unary ~'), 0, 0);
				}
		}
	}

	private function getAttr(obj:Value, attr:String):Value {
		return switch (obj) {
			case VInstance(_, fields):
				if (fields.exists(attr)) fields.get(attr); else throw new Error(AttributeError('no attribute ${attr}'), 0, 0);

			case VNativeObject(_, haxeObj):
				var field = Reflect.field(haxeObj, attr);

				if (Reflect.isFunction(field)) {
					return VNativeFunction(attr, function(args:Array<Value>):Value {
						var result = Reflect.callMethod(haxeObj, field, args.map(toHaxe));
						return toValue(result);
					});
				} else {
					return toValue(field);
				}

			case VNativeClass(_, cls):
				var staticField = Reflect.field(cls, attr);

				if (staticField == null)
					throw new Error(AttributeError('no attribute ${attr}'), 0, 0);

				if (Reflect.isFunction(staticField)) {
					return VNativeFunction(attr, function(args:Array<Value>):Value {
						var result = Reflect.callMethod(cls, staticField, args.map(toHaxe));
						return toValue(result);
					});
				} else {
					return toValue(staticField);
				}

			case VDict(map):
				// For dicts, attribute access is like map lookup.
				map.exists(attr) ? map.get(attr) : throw new Error(KeyError('${attr}'), 0, 0);

			default:
				throw new Error(AttributeError('no attribute ${attr}'), 0, 0);
		}
	}

	private function setAttr(obj:Value, attr:String, value:Value):Void {
		switch (obj) {
			case VInstance(_, fields):
				fields.set(attr, value);

			case VNativeObject(_, haxeObj):
				Reflect.setField(haxeObj, attr, toHaxe(value));

			case VDict(map):
				map.set(attr, value);

			default:
				throw new Error(AttributeError('cannot set attribute'), 0, 0);
		}
	}

	private function getSubscript(obj:Value, idx:Value):Value {
		return switch (obj) {
			case VList(items) | VTuple(items):
				var i = valueToInt(idx);
				if (i < 0 || i >= items.length)
					throw new Error(IndexError('index out of range'), 0, 0);
				items[i];

			case VDict(map):
				var key = valueToString(idx);
				map.exists(key) ? map.get(key) : throw new Error(KeyError('${key}'), 0, 0);

			case VString(s):
				var i = valueToInt(idx);
				if (i < 0 || i >= s.length)
					throw new Error(IndexError('index out of range'), 0, 0);
				VString(s.charAt(i));

			default:
				throw new Error(TypeError('object is not subscriptable'), 0, 0);
		}
	}

	private function setSubscript(obj:Value, idx:Value, value:Value):Void {
		switch (obj) {
			case VList(items):
				var i = valueToInt(idx);
				if (i < 0 || i >= items.length)
					throw new Error(IndexError('index out of range'), 0, 0);
				items[i] = value;

			case VDict(map):
				var key = valueToString(idx);
				map.set(key, value);

			default:
				throw new Error(TypeError('object does not support item assignment'), 0, 0);
		}
	}

	private function callFunction(func:Value, args:Array<Value>):Value {
		return switch (func) {
			case VFunction(f):
				// Recursion depth is current non-module frame count.
				if ((frames.length - 1) >= maxCallDepth)
					throw new Error(RecursionError("maximum recursion depth exceeded"), 0, 0);

				// User-defined function: create a new frame.
				pushFrame(f.code, f.globals);
				// Bind arguments to parameters.
				for (i in 0...args.length) {
					if (i < f.code.argNames.length) {
						frame.locals.set(f.code.argNames[i], args[i]);
					}
				}

				// Execute until RETURN_VALUE causes frame to be popped
				while (frames.length > 1 && frame.pc < f.code.instructions.length) {
					var instr = f.code.instructions[frame.pc];
					frame.pc++;
					executeInstruction(instr);
				}
				// Now get return value from caller's stack (frame is now caller)
				if (frame.stack.length > 0) {
					frame.stack.pop();
				} else {
					VNone;
				}

			case VNativeFunction(_, f):
				f(args);

			case VBuiltinType(name, constructor):
				constructor(args);

			case VNativeClass(name, cls):
				var instance = Type.createInstance(cls, args.map(toHaxe));
				VNativeObject(name, instance);

			case VNativeObject(_, haxeObj):
				if (Reflect.isFunction(haxeObj)) {
					var result = Reflect.callMethod(haxeObj, haxeObj, args.map(toHaxe));
					toValue(result);
				} else {
					throw new Error(TypeError('object is not callable'), 0, 0);
				}

			default:
				throw new Error(TypeError('object is not callable'), 0, 0);
		}
	}

	private function toIterator(obj:Value):Value {
		// For now, we'll just return the object itself if it's iterable.
		// A real implementation would track iterator state per object.
		return switch (obj) {
			case VList(_) | VTuple(_) | VString(_):
				// Wrap in an iterator object with an index.
				VNativeObject("iterator", {value: obj, index: 0});
			case VDict(map):
				// Cache keys once per iterator to avoid rebuilding key arrays
				// on every FOR_ITER step.
				var keys = [for (k in map.keys()) k];
				VNativeObject("iterator", {value: obj, index: 0, keys: keys});
			case VNativeObject("range_iterator", _):
				obj; // already a self-contained iterator, pass through unchanged
			default:
				throw new Error(TypeError('object is not iterable'), 0, 0);
		}
	}

	private function iteratorNext(iter:Value):Null<Value> {
		// Simplified: return null to signal StopIteration.
		return switch (iter) {
			case VNativeObject("iterator", state):
				var idx:Int = Reflect.field(state, "index");
				var val = Reflect.field(state, "value");

				var next = switch (val) {
					case VList(items) | VTuple(items):
						if (idx < items.length) {
							Reflect.setField(state, "index", idx + 1);
							items[idx];
						} else {
							null;
						}

					case VString(s):
						if (idx < s.length) {
							Reflect.setField(state, "index", idx + 1);
							VString(s.charAt(idx));
						} else {
							null;
						}

					case VDict(map):
						var keys:Array<String> = cast Reflect.field(state, "keys");
						if (idx < keys.length) {
							Reflect.setField(state, "index", idx + 1);
							VString(keys[idx]);
						} else {
							null;
						}

					default: null;
				}
				next;

			case VNativeObject("range_iterator", state):
				var idx:Int = Reflect.field(state, "index");
				var start:Int = Reflect.field(state, "start");
				var stop:Int = Reflect.field(state, "stop");
				var step:Int = Reflect.field(state, "step");
				var current = start + idx * step;
				var done = (step > 0) ? current >= stop : current <= stop;
				if (done)
					return null;
				Reflect.setField(state, "index", idx + 1);
				return VInt(current);

			default: null;
		}
	}

	// Convert a compile-time ConstValue to a runtime Value.
	private function valueFromConst(c:ConstValue):Value {
		return switch (c) {
			case CInt(v): VInt(v);
			case CFloat(v): VFloat(v);
			case CString(v): VString(v);
			case CBool(v): VBool(v);
			case CNone: VNone;
			case VObject(map):
				var newMap = new StringMap<Value>();
				for (k in map.keys())
					newMap.set(k, valueFromConst(map.get(k)));
				VDict(newMap);
			case VFunction(f):
				// Wrapped native function from compile-time
				throw new Error(TypeError('cannot convert VFunction from ConstValue'), 0, 0);
		}
	}

	// Convert a runtime Value to a Haxe type (Dynamic, with reflection fallback).
	public function toHaxe(v:Value):Dynamic {
		return switch (v) {
			case VInt(n): n;
			case VFloat(f): f;
			case VString(s): s;
			case VBool(b): b;
			case VNone: null;
			case VList(items): items.map(toHaxe);
			case VTuple(items): items.map(toHaxe);
			case VDict(map):
				var obj = {};
				for (k in map.keys())
					Reflect.setField(obj, k, toHaxe(map.get(k)));
				obj;
			case VNativeObject(_, obj): obj;
			default: null;
		}
	}

	// Convert a Haxe value to a runtime Value.
	public function toValue(v:Dynamic):Value {
		if (v == null)
			return VNone;
		if (Std.isOfType(v, Int))
			return VInt(cast v);
		if (Std.isOfType(v, Float))
			return VFloat(cast v);
		if (Std.isOfType(v, String))
			return VString(cast v);
		if (Std.isOfType(v, Bool))
			return VBool(cast v);
		if (Std.isOfType(v, Array)) {
			var arr:Array<Dynamic> = cast v;
			return VList(arr.map(toValue));
		}
		// For other types (classes, objects), wrap as native.
		return VNativeObject("haxe_object", v);
	}

	public function setNativeFunction(name:String, f:Function):Value {
		var wrapped = wrapNativeFunction(name, function(args:Array<Value>):Value {
			var haxeArgs = args.map(toHaxe);
			var result = Reflect.callMethod(null, f, haxeArgs);
			return toValue(result);
		});

		globals.set(name, wrapped);
		return wrapped;
	}

	public function setNativeClass(name:String, cls:Dynamic):Value {
		var wrapped = VNativeClass(name, cls);

		globals.set(name, wrapped);
		return wrapped;
	}

	public function setNative(name:String, obj:Dynamic):Value {
		if (Reflect.isFunction(obj)) {
			return setNativeFunction(name, obj);
		} else if (Std.isOfType(obj, Class)) {
			return setNativeClass(name, obj);
		} else {
			throw new Error(TypeError('unsupported native type'), 0, 0);
		}
	}

	// Wrap a Haxe function as a callable Python value.
	static function wrapNativeFunction(name:String, f:(Array<Value>) -> Value):Value {
		return VNativeFunction(name, f);
	}

	// Convert a Value to a human-readable string.
	static function valueToString(v:Value):String {
		return switch (v) {
			case VInt(n): Std.string(n);
			case VFloat(f): Std.string(f);
			case VString(s): s;
			case VBool(b): b ? "True" : "False";
			case VNone: "None";
			case VList(items): "[" + items.map(valueToString).join(", ") + "]";
			case VTuple(items): "(" + items.map(valueToString).join(", ") + ")";
			case VDict(map): "{...}"; // simplified
			case VFunction(_): "<function>";
			case VNativeFunction(n, _): "<native function: " + n + ">";
			case VNativeObject(n, _): "<" + n + ">";
			case VNativeClass(n, _): "<native class: " + n + ">";
			default: "<value>";
		}
	}

	// Convert a Value to an int (for indexing, etc.)
	static function valueToInt(v:Value):Int {
		return switch (v) {
			case VInt(n): n;
			case VFloat(f): Std.int(f);
			case VBool(b): b ? 1 : 0;
			default: throw new Error(TypeError('cannot convert to int'), 0, 0);
		}
	}

	// Check if a Value is truthy (for if/while/and/or).
	private static function isTruthy(v:Value):Bool {
		return switch (v) {
			case VBool(b): b;
			case VNone: false;
			case VInt(n): n != 0;
			case VFloat(f): f != 0.0;
			case VString(s): s.length > 0;
			case VList(items): items.length > 0;
			case VTuple(items): items.length > 0;
			case VDict(map): map.keys().hasNext();
			default: true;
		}
	}

	// Check value equality.
	static function valuesEqual(l:Value, r:Value):Bool {
		return switch ([l, r]) {
			case [VInt(a), VInt(b)]: a == b;
			case [VFloat(a), VFloat(b)]: a == b;
			case [VInt(a), VFloat(b)] | [VFloat(b), VInt(a)]: a == b;
			case [VString(a), VString(b)]: a == b;
			case [VBool(a), VBool(b)]: a == b;
			case [VNone, VNone]: true;
			case [VList(a), VList(b)]:
				if (a.length != b.length) false; else {
					var eq = true;
					for (i in 0...a.length)
						if (!valuesEqual(a[i], b[i])) {
							eq = false;
							break;
						}
					eq;
				}
			case [VTuple(a), VTuple(b)]: {
					if (a.length != b.length)
						return false;
					for (i in 0...a.length)
						if (!valuesEqual(a[i], b[i]))
							return false;
					true;
				}
			default: false;
		}
	}

	// Get a global variable (from Python code, accessible in Haxe).
	public function getGlobal(name:String):Value {
		return globals.exists(name) ? globals.get(name) : VNone;
	}

	// Set a global variable (from Haxe, accessible in Python code).
	public function setGlobal(name:String, value:Value):Void {
		globals.set(name, value);
	}

	public function getSemanticBindings():Array<String> {
		var seen = new StringMap<Bool>();
		var names:Array<String> = [];

		for (name in globals.keys()) {
			seen.set(name, true);
			names.push(name);
		}
		for (name in builtins.keys()) {
			if (!seen.exists(name)) {
				names.push(name);
			}
		}
		return names;
	}

	private function pushFrame(code:CodeObject, parentLocals:StringMap<Value>):Void {
		var newFrame:Frame = {
			code: code,
			pc: 0,
			locals: new StringMap<Value>(), // Will be populated by caller (arg binding, etc.)
			stack: []
		}
		frames.push(newFrame);
		frame = newFrame;
	}

	private function popFrame():Void {
		if (frames.length > 0) {
			frames.pop();
			frame = frames.length > 0 ? frames[frames.length - 1] : null;
		}
	}

	private inline function push(v:Value):Void {
		frame.stack.push(v);
	}

	private inline function pop():Value {
		if (frame.stack.length == 0)
			throw new Error(ValueError('stack underflow'), 0, 0);
		return frame.stack.pop();
	}

	private inline function peek():Value {
		if (frame.stack.length == 0)
			throw new Error(ValueError('stack underflow'), 0, 0);
		return frame.stack[frame.stack.length - 1];
	}

	private function popN(count:Int):Array<Value> {
		var items:Array<Value> = [];
		items.resize(count);
		for (i in 0...count)
			items[count - 1 - i] = pop();
		return items;
	}

	private function lookupName(name:String):Value {
		// Search locals first, then globals, then builtins.
		if (frame.locals.exists(name))
			return frame.locals.get(name);
		if (globals.exists(name))
			return globals.get(name);
		if (builtins.exists(name))
			return builtins.get(name);
		throw new Error(NameError('undefined variable: ${name}'), 0, 0);
	}

	private function initBuiltins():Void {
		// len(obj)
		builtins.set("len", VNativeFunction("len", (function(args:Array<Value>):Value {
			if (args.length != 1)
				throw new Error(TypeError('len() takes exactly 1 argument'), 0, 0);
			return switch (args[0]) {
				case VString(s): VInt(s.length);
				case VList(items): VInt(items.length);
				case VTuple(items): VInt(items.length);
				case VDict(map): VInt(Lambda.count(map));
				default: throw new Error(TypeError('object has no len()'), 0, 0);
			}
		})));

		// print(…)
		builtins.set("print", VNativeFunction("print", (function(args:Array<Value>):Value {
			trace(args.map(valueToString).join(" "));
			return VNone;
		})));

		// range(n) or range(start, stop, step)
		builtins.set("range", VNativeFunction("range", (function(args:Array<Value>):Value {
			if (args.length < 1 || args.length > 3)
				throw new Error(TypeError('range() takes 1 to 3 arguments'), 0, 0);

			var start = 0, stop = 0, step = 1;
			if (args.length == 1) {
				stop = valueToInt(args[0]);
			} else {
				start = valueToInt(args[0]);
				stop = valueToInt(args[1]);
				if (args.length == 3)
					step = valueToInt(args[2]);
			}
			// Return a lazy range iterator object instead of a pre-baked list
			return VNativeObject("range_iterator", {
				start: start,
				stop: stop,
				step: step,
				index: 0
			});
		})));

		// type(obj)
		builtins.set("type", VNativeFunction("type", (function(args:Array<Value>):Value {
			if (args.length != 1)
				throw new Error(TypeError('type() takes exactly 1 argument'), 0, 0);
			var obj = args[0];
			return switch (obj) {
				case VInt(_): VString("int");
				case VFloat(_): VString("float");
				case VString(_): VString("str");
				case VBool(_): VString("bool");
				case VNone: VString("NoneType");
				case VList(_): VString("list");
				case VTuple(_): VString("tuple");
				case VDict(_): VString("dict");
				case VFunction(_): VString("function");
				case VBuiltinType(name, _): VString(name);
				case VNativeObject(name, _): VString(name);
				case VNativeClass(name, _): VString(name);
				default: VString("object");
			}
		})));

		// int(x)
		builtins.set("int", VBuiltinType("int", (function(args:Array<Value>):Value {
			if (args.length == 0)
				return VInt(0);
			if (args.length != 1)
				throw new Error(TypeError('int() takes at most 1 argument'), 0, 0);
			return VInt(valueToInt(args[0]));
		})));

		// str(x)
		builtins.set("str", VBuiltinType("str", (function(args:Array<Value>):Value {
			if (args.length == 0)
				return VString("");
			if (args.length != 1)
				throw new Error(TypeError('str() takes at most 1 argument'), 0, 0);
			return VString(valueToString(args[0]));
		})));

		// bool(x)
		builtins.set("bool", VBuiltinType("bool", (function(args:Array<Value>):Value {
			if (args.length == 0)
				return VBool(false);
			if (args.length != 1)
				throw new Error(TypeError('bool() takes at most 1 argument'), 0, 0);
			return VBool(isTruthy(args[0]));
		})));

		// list(x)
		builtins.set("list", VBuiltinType("list", (function(args:Array<Value>):Value {
			if (args.length == 0)
				return VList([]);
			if (args.length != 1)
				throw new Error(TypeError('list() takes at most 1 argument'), 0, 0);
			return switch (args[0]) {
				case VList(items): VList(items.copy());
				case VTuple(items): VList(items.copy());
				case VString(s): VList([for (i in 0...s.length) VString(s.charAt(i))]);
				default: throw new Error(TypeError('not iterable'), 0, 0);
			}
		})));

		// tuple(x)
		builtins.set("tuple", VBuiltinType("tuple", (function(args:Array<Value>):Value {
			if (args.length == 0)
				return VTuple([]);
			if (args.length != 1)
				throw new Error(TypeError('tuple() takes at most 1 argument'), 0, 0);
			return switch (args[0]) {
				case VList(items): VTuple(items.copy());
				case VTuple(items): VTuple(items.copy());
				case VString(s): VTuple([for (i in 0...s.length) VString(s.charAt(i))]);
				default: throw new Error(TypeError('not iterable'), 0, 0);
			}
		})));

		// dict()
		builtins.set("dict", VBuiltinType("dict", (function(args:Array<Value>):Value {
			if (args.length == 0)
				return VDict(new StringMap<Value>());
			throw new Error(TypeError('dict() with args not yet supported'), 0, 0);
		})));
	}

	// Debugging
	// Return a string representation of the current frame's stack (for debugging).
	public function stackDump():String {
		var parts = [];
		for (v in frame.stack)
			parts.push(valueToString(v));
		return "[" + parts.join(" | ") + "]";
	}

	// Return a string representation of globals (for debugging).
	public function globalsDump():String {
		var parts = [];
		for (k in globals.keys())
			parts.push(k + " = " + valueToString(globals.get(k)));
		return "{" + parts.join(", ") + "}";
	}

	private inline function pass() {}

	public static function runFromSource(source:String, ?filename:String):String {
		var lexer = new Lexer(source);
		var ast = lexer.tokenize();
		var code = new Parser(ast, lexer.tokenPositions).parse();
		Semantic.analyze(code, filename != null ? filename : "<module>");
		var bytes = new Compiler().compile(code);
		var vm = new VM();
		var result = vm.execute(bytes);
		return valueToString(result);
	}

	public static function runFromFile(filename:String):String {
		#if sys
		var source = sys.io.File.getContent(filename);
		return runFromSource(source, filename);
		#else
		throw new Error(CustomError('runFromFile is not supported on this platform'), 0, 0);
		#end
	}
}
