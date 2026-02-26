package paopao.hython;

import paopao.hython.Objects.Dict;
import paopao.hython.Expr;
import paopao.hython.Interp as PyInterp;

@:allow(paopao.hython.Interp)
class Buildin {
	private static function createBuiltinModule(interp:PyInterp, moduleName:String):Dynamic {
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

			case "random":
				var randomModule = new Dict();

				// Seed storage (using a static variable would be better in production)
				var seedValue:Null<Int> = null;
				var seeded:Bool = false;

				randomModule.set("seed", function(?a:Dynamic) {
					if (a != null) {
						seedValue = Std.int(Std.parseFloat(Std.string(a)));
						// Note: Haxe's Math.random() doesn't support seeding directly
						// You would need a custom PRNG implementation for true seeding
						// This is a placeholder that acknowledges the seed was set
						seeded = true;
					} else {
						// Seed with current time
						seedValue = Std.int(Date.now().getTime());
						seeded = true;
					}
					return null;
				});

				randomModule.set("random", function() {
					return Math.random();
				});

				randomModule.set("randint", function(a:Dynamic, b:Dynamic) {
					var min = Std.int(Std.parseFloat(Std.string(a)));
					var max = Std.int(Std.parseFloat(Std.string(b)));
					return min + Math.floor(Math.random() * (max - min + 1));
				});

				randomModule.set("choice", function(arr:Array<Dynamic>) {
					if (arr.length == 0)
						return null;
					return arr[Math.floor(Math.random() * arr.length)];
				});

				randomModule.set("shuffle", function(arr:Array<Dynamic>) {
					// Fisher-Yates shuffle
					for (i in 0...arr.length) {
						var j = Math.floor(Math.random() * (i + 1));
						var temp = arr[i];
						arr[i] = arr[j];
						arr[j] = temp;
					}
					return null;
				});

				randomModule.set("uniform", function(a:Dynamic, b:Dynamic) {
					var min = Std.parseFloat(Std.string(a));
					var max = Std.parseFloat(Std.string(b));
					return min + Math.random() * (max - min);
				});

				return randomModule;

			case "json":
				var jsonModule = new Dict();
				jsonModule.set("dumps", function(obj:Dynamic, ?indent:Dynamic) {
					// Convert to JSON string
					return haxe.Json.stringify(obj, null, indent != null ? "  " : null);
				});
				jsonModule.set("loads", function(str:String) {
					// Parse JSON string
					return haxe.Json.parse(str);
				});
				return jsonModule;

			case "datetime":
				var datetimeModule = new Dict();

				// datetime class
				var datetimeClass = function(?year:Dynamic, ?month:Dynamic, ?day:Dynamic, ?hour:Dynamic, ?minute:Dynamic, ?second:Dynamic) {
					var dt = new Dict();
					var date = Date.now();

					if (year != null) {
						var y = year != null ? Std.int(Std.parseFloat(Std.string(year))) : date.getFullYear();
						var mo = month != null ? Std.int(Std.parseFloat(Std.string(month))) : date.getMonth() + 1;
						var d = day != null ? Std.int(Std.parseFloat(Std.string(day))) : date.getDate();
						var h = hour != null ? Std.int(Std.parseFloat(Std.string(hour))) : 0;
						var mi = minute != null ? Std.int(Std.parseFloat(Std.string(minute))) : 0;
						var s = second != null ? Std.int(Std.parseFloat(Std.string(second))) : 0;

						date = new Date(y, mo - 1, d, h, mi, s);
					}

					dt.set("year", date.getFullYear());
					dt.set("month", date.getMonth() + 1);
					dt.set("day", date.getDate());
					dt.set("hour", date.getHours());
					dt.set("minute", date.getMinutes());
					dt.set("second", date.getSeconds());
					dt.set("_date", date);

					dt.set("strftime", function(format:String) {
						var result = format;
						result = StringTools.replace(result, "%Y", Std.string(date.getFullYear()));
						result = StringTools.replace(result, "%m", StringTools.lpad(Std.string(date.getMonth() + 1), "0", 2));
						result = StringTools.replace(result, "%d", StringTools.lpad(Std.string(date.getDate()), "0", 2));
						result = StringTools.replace(result, "%H", StringTools.lpad(Std.string(date.getHours()), "0", 2));
						result = StringTools.replace(result, "%M", StringTools.lpad(Std.string(date.getMinutes()), "0", 2));
						result = StringTools.replace(result, "%S", StringTools.lpad(Std.string(date.getSeconds()), "0", 2));
						return result;
					});

					dt.set("isoformat", function() {
						return date.toString();
					});

					return dt;
				};

				datetimeModule.set("datetime", datetimeClass);
				datetimeModule.set("now", function() {
					return datetimeClass();
				});

				return datetimeModule;

			case "re":
				var reModule = new Dict();

				reModule.set("compile", function(pattern:String, ?flags:Dynamic) {
					var compiledPattern = new Dict();
					var ereg = new EReg(pattern, flags != null ? Std.string(flags) : "");

					compiledPattern.set("match", function(str:String) {
						return ereg.match(str);
					});

					compiledPattern.set("search", function(str:String) {
						if (ereg.match(str)) {
							var matchObj = new Dict();
							matchObj.set("group", function(?n:Dynamic) {
								if (n == null || n == 0) {
									return ereg.matched(0);
								}
								return ereg.matched(Std.int(Std.parseFloat(Std.string(n))));
							});
							return matchObj;
						}
						return null;
					});

					compiledPattern.set("findall", function(str:String) {
						var matches = [];
						var pos = 0;
						var tempStr = str;
						while (ereg.match(tempStr)) {
							matches.push(ereg.matched(0));
							var matchedPos = ereg.matchedPos();
							tempStr = tempStr.substring(matchedPos.pos + matchedPos.len);
						}
						return matches;
					});

					compiledPattern.set("sub", function(replacement:String, str:String, ?count:Dynamic) {
						return ereg.replace(str, replacement);
					});

					return compiledPattern;
				});

				reModule.set("match", function(pattern:String, str:String, ?flags:Dynamic) {
					var ereg = new EReg(pattern, flags != null ? Std.string(flags) : "");
					return ereg.match(str);
				});

				reModule.set("search", function(pattern:String, str:String, ?flags:Dynamic) {
					var ereg = new EReg(pattern, flags != null ? Std.string(flags) : "");
					if (ereg.match(str)) {
						var matchObj = new Dict();
						matchObj.set("group", function(?n:Dynamic) {
							if (n == null || n == 0) {
								return ereg.matched(0);
							}
							return ereg.matched(Std.int(Std.parseFloat(Std.string(n))));
						});
						return matchObj;
					}
					return null;
				});

				reModule.set("findall", function(pattern:String, str:String, ?flags:Dynamic) {
					var ereg = new EReg(pattern, flags != null ? Std.string(flags) : "");
					var matches = [];
					var tempStr = str;
					while (ereg.match(tempStr)) {
						matches.push(ereg.matched(0));
						var matchedPos = ereg.matchedPos();
						tempStr = tempStr.substring(matchedPos.pos + matchedPos.len);
					}
					return matches;
				});

				reModule.set("sub", function(pattern:String, replacement:String, str:String, ?count:Dynamic, ?flags:Dynamic) {
					var ereg = new EReg(pattern, flags != null ? Std.string(flags) : "");
					return ereg.replace(str, replacement);
				});

				return reModule;

			default:
				return null;
		}
	}
}
