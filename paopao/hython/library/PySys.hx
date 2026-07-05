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
	public static final version_info:{
		major:Int,
		minor:Int,
		micro:Int,
		releaselevel:String,
		serial:Int
	} = {
		"major": 3,
		"minor": 13,
		"micro": 14,
		"releaselevel": "final",
		"serial": 0
	};
	public static final implementation:{name:String, version:String} = {
		"name": "hython",
		"version": "0.1.0"
	};

	public static final executable:String = Sys.programPath();
	public static final byteorder:String = "little";

	public static final maxsize:Int = 2147483647;
	public static final api_version:Int = 1013;

	public static var builtin_module_names(get, never):Iterator<String>;
	static function get_builtin_module_names():Iterator<String> {
		return Library.entries().keys();
	}

	public static final float_info:{max:Float, min:Float, epsilon:Float} = {
		"max": 1.7976931348623157e+308,
		"min": 2.2250738585072014e-308,
		"epsilon": 2.220446049250313e-16
	};

	public static final int_info:{bits:Int, max:Int, min:Int} = {
		"bits": 32,
		"max": 2147483647,
		"min": -2147483648
	};

	public static function exit(?code:Int = 0):Void {
		Sys.exit(code);
	}

	public static function getsizeof(obj:Dynamic):Int {
		return haxe.io.Bytes.ofString(haxe.Serializer.run(obj)).length;
	}

	public static function getrecursionlimit():Int {
		return 1000;
	}

	public static function setrecursionlimit(limit:Int):Void {}

	public static function intern(str:String):String {
		return str;
	}

	public static function exc_info():Dynamic {
		return {
            "type": null,
            "value": null,
            "traceback": null
        };
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
