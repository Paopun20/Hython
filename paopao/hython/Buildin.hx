package paopao.hython;
import paopao.hython.Objects.Dict;

@:allow(paopao.hython.Interp)
class Buildin {
    private static function createBuiltinModule(moduleName:String):Dynamic {
		switch (moduleName) {
			case "math":
				var mathModule = new Dict();
				mathModule.set("sqrt", function(x:Dynamic) {
					return Math.sqrt(Std.parseFloat(Std.string(x)));
				});
				mathModule.set("pow", function(base:Dynamic, exp:Dynamic) {
					return Math.pow(Std.parseFloat(Std.string(base)), Std.parseFloat(Std.string(exp)));
				});
				mathModule.set("sin", function(x:Dynamic) {
					return Math.sin(Std.parseFloat(Std.string(x)));
				});
				mathModule.set("cos", function(x:Dynamic) {
					return Math.cos(Std.parseFloat(Std.string(x)));
				});
				mathModule.set("tan", function(x:Dynamic) {
					return Math.tan(Std.parseFloat(Std.string(x)));
				});
				mathModule.set("floor", function(x:Dynamic) {
					return Math.floor(Std.parseFloat(Std.string(x)));
				});
				mathModule.set("ceil", function(x:Dynamic) {
					return Math.ceil(Std.parseFloat(Std.string(x)));
				});
				mathModule.set("abs", function(x:Dynamic) {
					var n = Std.parseFloat(Std.string(x));
					return n < 0 ? -n : n;
				});
				mathModule.set("pi", Math.PI);
				mathModule.set("e", 2.718281828459045); // Euler's number
				return mathModule;
   
			case "os":
				var osModule = new Dict();
   
				#if sys
				// Path operations
				osModule.set("getcwd", function() {
					return Sys.getCwd();
				});
				osModule.set("chdir", function(path:String) {
					Sys.setCwd(path);
					return null;
				});
				osModule.set("listdir", function(path:String) {
					return sys.FileSystem.readDirectory(path);
				});
				osModule.set("mkdir", function(path:String) {
					sys.FileSystem.createDirectory(path);
					return null;
				});
				osModule.set("rmdir", function(path:String) {
					sys.FileSystem.deleteDirectory(path);
					return null;
				});
				osModule.set("remove", function(path:String) {
					sys.FileSystem.deleteFile(path);
					return null;
				});
				osModule.set("rename", function(oldPath:String, newPath:String) {
					sys.FileSystem.rename(oldPath, newPath);
					return null;
				});
				osModule.set("exists", function(path:String) {
					return sys.FileSystem.exists(path);
				});
				osModule.set("isdir", function(path:String) {
					return sys.FileSystem.isDirectory(path);
				});
				osModule.set("isfile", function(path:String) {
					return sys.FileSystem.exists(path) && !sys.FileSystem.isDirectory(path);
				});
   
				// Environment variables
				osModule.set("getenv", function(name:String, ?defaultValue:String) {
					var value = Sys.getEnv(name);
					return value != null ? value : defaultValue;
				});
				osModule.set("putenv", function(name:String, value:String) {
					Sys.putEnv(name, value);
					return null;
				});
				osModule.set("environ", Sys.environment());
   
				// System info
				osModule.set("name", Sys.systemName());
   
				// Path module (os.path)
				var pathModule = new Dict();
				pathModule.set("join", Reflect.makeVarArgs(function(parts:Array<Dynamic>) {
					var sep = Sys.systemName() == "Windows" ? "\\" : "/";
					return parts.join(sep);
				}));
				pathModule.set("basename", function(path:String) {
					var parts = path.split("/");
					if (parts.length == 0) {
						parts = path.split("\\");
					}
					return parts[parts.length - 1];
				});
				pathModule.set("dirname", function(path:String) {
					var sep = path.indexOf("\\") >= 0 ? "\\" : "/";
					var parts = path.split(sep);
					parts.pop();
					return parts.join(sep);
				});
				pathModule.set("exists", function(path:String) {
					return sys.FileSystem.exists(path);
				});
				pathModule.set("isdir", function(path:String) {
					return sys.FileSystem.isDirectory(path);
				});
				pathModule.set("isfile", function(path:String) {
					return sys.FileSystem.exists(path) && !sys.FileSystem.isDirectory(path);
				});
				pathModule.set("abspath", function(path:String) {
					return sys.FileSystem.absolutePath(path);
				});
   
				osModule.set("path", pathModule);
				#else
				// Non-sys targets get stub functions
				osModule.set("getcwd", function() {
					return ".";
				});
				osModule.set("name", "unknown");
				#end
   
				return osModule;
   
			default:
				return null;
		}
	}
}