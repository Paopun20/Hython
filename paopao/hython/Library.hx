package paopao.hython;

import haxe.ds.StringMap;

class Library {
	static var libReg:StringMap<Class<Dynamic>> = new StringMap<Class<Dynamic>>();
	static var initialized:Bool = false;

	static function ensureInit() {
		if (initialized) return;
		initialized = true;
		// Register built-in libraries
		add(paopao.hython.library.PyOS, "os");
		add(paopao.hython.library.PySys, "sys");
		add(paopao.hython.library.PyJson, "json");
		add(paopao.hython.library.PyTomlLib, "tomllib");
	}

	public static function add(libClass:Class<Dynamic>, ?name:String):Bool {
		var libName = name != null ? name : className(libClass);
		if (libReg.exists(libName))
			return false;

		libReg.set(libName, libClass);
		return true;
	}

	public static function get(name:String):Null<Class<Dynamic>> {
		ensureInit();
		return libReg.get(name);
	}

	public static function entries():StringMap<Class<Dynamic>> {
		ensureInit();
		var result = new StringMap<Class<Dynamic>>();
		for (name in libReg.keys())
			result.set(name, libReg.get(name));
		return result;
	}

	public static function exists(name:String):Bool {
		ensureInit();
		return libReg.exists(name);
	}

	public static function remove(name:String):Bool {
		ensureInit();
		return libReg.remove(name);
	}

	public static function clear():Void {
		ensureInit();
		libReg = new StringMap<Class<Dynamic>>();
	}

	public static function names():Array<String> {
		ensureInit();
		return [for (name in libReg.keys()) name];
	}

	static function className(libClass:Class<Dynamic>):String {
		var fullName = Type.getClassName(libClass);
		var parts = fullName.split(".");
		return parts[parts.length - 1];
	}
}
