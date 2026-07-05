package paopao.hython;

import haxe.ds.StringMap;
import paopao.hython.library.*;

class Library {
	static var libReg:StringMap<Class<Dynamic>> = new StringMap<Class<Dynamic>>();

	/*
		Initialize the library registry with built-in libraries.
		This method is called automatically when the Library class is first accessed.
	*/
	static function __init__() {
		// Register built-in libraries
		add(PyOS, "os");
		add(PySys, "sys");
		add(PyJson, "json");
		add(PyTomlLib, "tomllib");
		// add(PyMath, "math");
		// add(PyRandom, "random");
		// add(PyTime, "time");
		// add(PyRe, "re");
		// add(PyJson, "json");
		// add(PyIO, "io");
		// add(PyShutil, "shutil");
		// add(PySubprocess, "subprocess");
		// add(PyThreading, "threading");
		// add(PyMultiprocessing, "multiprocessing");
		// add(PySocket, "socket");
		// add(PySelect, "select");
		// add(PySignal, "signal");
		// add(PyLogging, "logging");
	}

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
