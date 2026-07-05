package paopao.hython.library;

import paopao.hython.Library;
import haxe.ds.StringMap;

class PySys {
	public static final argv:Array<String> = Sys.args();
	public static final path:Array<String> = ["."];
	public static final modules:StringMap<Dynamic> = new StringMap();

	public static final platform:String = switch (Sys.systemName()) {
			case "Windows": "win32";
			case "Mac": "darwin";
			case "Linux": "linux";
			default: "unknown";
		};

	public static final version:String = "3.13.14 (Hython 0.1.0)";
	public static final version_info:Map<String, Dynamic> = {
		"major": 3,
		"minor": 13,
		"micro": 14,
		"releaselevel": "final",
		"serial": 0
	};
	public static final implementation:Map<String, String> = {
		"name": "hython",
		"version": "0.1.0"
	};

	public static final executable:String = Sys.executablePath();
	public static final byteorder:String = "little"; // haxe does not provide a direct way to get the byte order, but most modern systems are little-endian.

	public static final maxsize:Int = 2147483647;
	public static final api_version:Int = 1013;

	public static final builtin_module_names:Array<String> = Library.entries().keys();

	public static final float_info:Map<String, Float> = {
		"max": 1.7976931348623157e+308,
		"min": 2.2250738585072014e-308,
		"epsilon": 2.220446049250313e-16
	};

	public static final int_info:Map<String, Int> = {
		"bits": 32,
		"max": 2147483647,
		"min": -2147483648
	};

	public static function exit(?code:Int = 0):Void {
		Sys.exit(code);
	}

	public static function getsizeof(obj:Dynamic):Int {
		// In Haxe, we don't have a direct way to get the size of an object in memory.
		// This is a placeholder implementation. You may want to implement a more accurate method if needed.
		return 0;
	}

	public static function getrecursionlimit():Int {
		return 1000;
	}

	public static function setrecursionlimit(limit:Int):Void {
		// just do nothing
	}

	public static function intern(str:String):String {
		return str;
	}

	public static function exc_info():Dynamic {
		return null;
	}

	public static function stdout_write(text:String):Void {
		Sys.print(text);
	}

	public static function stderr_write(text:String):Void {
		Sys.stderr().writeString(text);
	}

	public static function stdin_readLine():String {
		return Sys.stdin().readLine();
	}
}
