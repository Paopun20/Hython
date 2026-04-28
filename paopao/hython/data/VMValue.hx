// VMValue.hx
package paopao.hython.data;

import haxe.ds.StringMap;
import paopao.hython.Bytecode;

typedef ClassDef = {
	name:String,
	bases:Array<Value>, // Parent classes
	methods:StringMap<Value>, // Methods (as VFunction)
	fields:StringMap<Value>, // Class variables
}

typedef PythonFunction = {
	code:CodeObject,
	globals:StringMap<Value>, // Closure: reference to enclosing scope
	// locals are stored in stack frames, not here
}

typedef GeneratorState = {
	// Placeholder for generator support (yield)
	dummy:Int
}

typedef CoroutineState = {
	// Placeholder for async/await support
	dummy:Int
}

enum Value {
	// Primitives
	VInt(v:Int);
	VFloat(v:Float);
	VString(v:String);
	VBool(v:Bool);
	VNone;

	// Collections
	VList(items:Array<Value>);
	VTuple(items:Array<Value>);
	VDict(map:StringMap<Value>);

	// Callables
	VFunction(func:PythonFunction); // User-defined Python function
	VNativeFunction(name:String, func:(Array<Value>) -> Value); // Wrapped Haxe function (hookable from Haxe)
	VBuiltinType(name:String, constructor:(Array<Value>) -> Value); // e.g., int, str, list

	// Object-oriented
	VClass(classDef:ClassDef); // Class (type) object
	VInstance(className:String, fields:StringMap<Value>); // Class instance
	VNativeClass(name:String, cls:Dynamic); // Wrapped Haxe class with ctor + static attrs

	// Interop
	VNativeObject(name:String, obj:Dynamic); // Wrapped Haxe object

	// Future
	VGenerator(gen:GeneratorState);
	VCoroutine(coro:CoroutineState);
}
