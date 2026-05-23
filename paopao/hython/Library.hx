package paopao.hython;

import haxe.ds.StringMap;

interface IPyClassAble {}

class Library {
	static var libReg:StringMap<Class<Dynamic>> = new StringMap<Class<Dynamic>>();

	public static function add(libClass:Class<Dynamic>, ?name:String):Bool {
		var libName = name != null ? name : className(libClass);
		if (libReg.exists(libName))
			return false;

		libReg.set(libName, libClass);
		return true;
	}

	public static function get(name:String):Null<Class<Dynamic>> {
		return libReg.get(name);
	}

	public static function entries():StringMap<Class<Dynamic>> {
		var result = new StringMap<Class<Dynamic>>();
		for (name in libReg.keys())
			result.set(name, libReg.get(name));
		return result;
	}

	public static function exists(name:String):Bool {
		return libReg.exists(name);
	}

	public static function remove(name:String):Bool {
		return libReg.remove(name);
	}

	public static function clear():Void {
		libReg = new StringMap<Class<Dynamic>>();
	}

	public static function names():Array<String> {
		return [for (name in libReg.keys()) name];
	}

	static function className(libClass:Class<Dynamic>):String {
		var fullName = Type.getClassName(libClass);
		var parts = fullName.split(".");
		return parts[parts.length - 1];
	}
}
