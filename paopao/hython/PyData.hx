package paopao.hython;

import paopao.hython.Ast;
import haxe.ds.StringMap;
import haxe.ds.Vector;

class PyScope {
	public var parent:PyScope;
	public var locals:Map<String, Bool>;

	public function new(parent:PyScope) {
		this.parent = parent;
		this.locals = new Map();
	}

	public function define(name:String) {
		locals.set(name, true);
	}

	public function exists(name:String):Bool {
		if (locals.exists(name))
			return true;
		if (parent != null)
			return parent.exists(name);
		return false;
	}
}

enum PyClass {
	FUser(name:String, bases:Array<PyValue>, // Parent classes
		methods:StringMap<PyValue>, // Methods
		fields:StringMap<PyValue> // Class variables
	);
	FNative(name:String, methods:StringMap<PyValue>, fields:StringMap<PyValue>);
}

enum PyFunction {
	FUser(name:String, params:Vector<String>, body:Vector<Stmt>);
	FNative(name:String, params:Vector<String>, onCall:Vector<PyValue>->PyValue);
}

enum PyType {
	// Primitive types
	TInt;
	TFloat;
	TString;
	TBool;
	TNone;

	// Collection types
	TList;
	TTuple;
	TDict;
	// Callable types
	TFunction;

	// OOP types
	TClass;
	TInstance;
}

enum PyValue {
	// Primitives
	VInt(v:Int);
	VFloat(v:Float);
	VString(v:String);
	VBool(v:Bool);
	VNone;

	// Collections
	VList(items:Array<PyValue>);
	VTuple(items:Array<PyValue>);
	VDict(map:StringMap<PyValue>);
	// Callables
	VFunction(func:PyFunction); // User-defined Python function and Native function

	// Object-oriented
	VClass(classDef:PyClass); // Class (type) object
	VInstance(cls:PyClass, fields:StringMap<PyValue>); // Class instance
}
