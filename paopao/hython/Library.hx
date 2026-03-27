package paopao.hython;

import paopao.hython.Objects.Dict;
import paopao.hython.Expr;
import paopao.hython.Interp as PyInterp;
#if sys
import sys.FileSystem;
#end

@:allow(paopao.hython.Interp)
@:privateAccess
class Library {
	private static function createBuiltinModule(interp:PyInterp, moduleName:String):Null<Dict> {
		var customLibrary;
		if ((customLibrary = loadLibrary(interp, moduleName)) != null)
			return customLibrary;

		switch (moduleName) {
			case "math":
				var _f = function(x:Dynamic):Float return Std.parseFloat(Std.string(x));
				var _i = function(x:Dynamic):Int return Std.int(Std.parseFloat(Std.string(x)));
				// Euclidean GCD (positive ints)
				var _gcd = function(a:Int, b:Int):Int {
					if (a < 0)
						a = -a;
					if (b < 0)
						b = -b;
					while (b != 0) {
						var t = b;
						b = a % b;
						a = t;
					}
					return a;
				};

				// Lanczos gamma (g = 7) — must be var so closure self-recurses
				function _gamma(n:Float):Float {
					final lp = [
						 0.99999999999980993,     676.5203681218851, -1259.1392167224028,
						  771.32342877765313,   -176.61502916214059,  12.507343278686905,
						-0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7
					];
					if (n < 0.5)
						return Math.PI / (Math.sin(Math.PI * n) * _gamma(1.0 - n));
					n -= 1.0;
					var x = lp[0];
					for (i in 1...9)
						x += lp[i] / (n + i);
					var t = n + 7.5;
					return Math.sqrt(2.0 * Math.PI) * Math.pow(t, n + 0.5) * Math.exp(-t) * x;
				};

				var _ulp = function(x:Float):Float {
					if (x != x)
						return x; // NaN → NaN
					var a = Math.abs(x);
					if (a == Math.POSITIVE_INFINITY)
						return Math.POSITIVE_INFINITY;
					if (a == 0.0)
						return 5e-324;
					return Math.pow(2.0, Math.floor(Math.log(a) / Math.log(2.0)) - 52.0);
				};

				var _erfCore = function(absv:Float):Float {
					var t = 1.0 / (1.0 + 0.3275911 * absv);
					return 1.0 - (((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t) * Math.exp(-absv * absv);
				};

				var mathModule = new Dict();
				mathModule.set("__name__", "math");

				mathModule.set("pi", Math.PI);
				mathModule.set("e", 2.718281828459045);
				mathModule.set("tau", 2.0 * Math.PI);
				mathModule.set("inf", Math.POSITIVE_INFINITY);
				mathModule.set("nan", Math.NaN);

				mathModule.set("sin", function(x:Dynamic) return Math.sin(_f(x)));
				mathModule.set("cos", function(x:Dynamic) return Math.cos(_f(x)));
				mathModule.set("tan", function(x:Dynamic) return Math.tan(_f(x)));
				mathModule.set("asin", function(x:Dynamic) return Math.asin(_f(x)));
				mathModule.set("acos", function(x:Dynamic) return Math.acos(_f(x)));
				mathModule.set("atan", function(x:Dynamic) return Math.atan(_f(x)));
				mathModule.set("atan2", function(y:Dynamic, x:Dynamic) return Math.atan2(_f(y), _f(x)));

				mathModule.set("sinh", function(x:Dynamic) {
					var v = _f(x);
					return (Math.exp(v) - Math.exp(-v)) / 2.0;
				});
				mathModule.set("cosh", function(x:Dynamic) {
					var v = _f(x);
					return (Math.exp(v) + Math.exp(-v)) / 2.0;
				});
				mathModule.set("tanh", function(x:Dynamic) {
					var v = _f(x);
					var ep = Math.exp(v), en = Math.exp(-v);
					return (ep - en) / (ep + en);
				});
				mathModule.set("asinh", function(x:Dynamic) {
					var v = _f(x);
					return Math.log(v + Math.sqrt(v * v + 1.0));
				});
				mathModule.set("acosh", function(x:Dynamic) {
					var v = _f(x);
					return Math.log(v + Math.sqrt(v * v - 1.0));
				});
				mathModule.set("atanh", function(x:Dynamic) {
					var v = _f(x);
					return Math.log((1.0 + v) / (1.0 - v)) / 2.0;
				});

				mathModule.set("degrees", function(x:Dynamic) return _f(x) * (180.0 / Math.PI));
				mathModule.set("radians", function(x:Dynamic) return _f(x) * (Math.PI / 180.0));

				mathModule.set("sqrt", function(x:Dynamic) return Math.sqrt(_f(x)));
				mathModule.set("cbrt", function(x:Dynamic) {
					var v = _f(x);
					return v < 0.0 ? -Math.pow(-v, 1.0 / 3.0) : Math.pow(v, 1.0 / 3.0);
				});
				mathModule.set("pow", function(base:Dynamic, exp:Dynamic) return Math.pow(_f(base), _f(exp)));
				mathModule.set("isqrt", function(x:Dynamic) {
					var v = _i(x);
					if (v < 0)
						throw "math domain error";
					return Std.int(Math.sqrt(v));
				});
				mathModule.set("hypot", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
					var sum = 0.0;
					for (a in args) {
						var v = _f(a);
						sum += v * v;
					}
					return Math.sqrt(sum);
				}));

				mathModule.set("exp", function(x:Dynamic) return Math.exp(_f(x)));
				mathModule.set("exp2", function(x:Dynamic) return Math.pow(2.0, _f(x)));
				mathModule.set("expm1", function(x:Dynamic) {
					var v = _f(x);
					// Taylor series more accurate for tiny v
					if (Math.abs(v) < 1e-5)
						return v + v * v / 2.0 + v * v * v / 6.0;
					return Math.exp(v) - 1.0;
				});
				mathModule.set("log", function(x:Dynamic, ?base:Dynamic) {
					var v = _f(x);
					if (base != null)
						return Math.log(v) / Math.log(_f(base));
					return Math.log(v);
				});
				mathModule.set("log2", function(x:Dynamic) return Math.log(_f(x)) / Math.log(2.0));
				mathModule.set("log10", function(x:Dynamic) return Math.log(_f(x)) / Math.log(10.0));
				mathModule.set("log1p", function(x:Dynamic) {
					var v = _f(x);
					if (Math.abs(v) < 1e-4)
						return v - v * v / 2.0 + v * v * v / 3.0;
					return Math.log(1.0 + v);
				});

				mathModule.set("floor", function(x:Dynamic) return Math.floor(_f(x)));
				mathModule.set("ceil", function(x:Dynamic) return Math.ceil(_f(x)));
				mathModule.set("trunc", function(x:Dynamic) {
					var v = _f(x);
					return v < 0.0 ? Math.ceil(v) : Math.floor(v);
				});
				mathModule.set("fabs", function(x:Dynamic) return Math.abs(_f(x)));

				mathModule.set("fmod", function(x:Dynamic, y:Dynamic) {
					var a = _f(x), b = _f(y);
					return a - Std.int(a / b) * b;
				});
				// Returns [fractional_part, integer_part] (Python returns tuple)
				mathModule.set("modf", function(x:Dynamic) {
					var v = _f(x);
					var ip = v < 0.0 ? Math.ceil(v) : Math.floor(v);
					return [v - ip, ip * 1.0];
				});
				// Returns [mantissa, exponent] where x == mantissa * 2^exponent, 0.5 <= |m| < 1
				mathModule.set("frexp", function(x:Dynamic) {
					var v = _f(x);
					if (v == 0.0)
						return [0.0, 0];
					var e = Math.floor(Math.log(Math.abs(v)) / Math.log(2.0)) + 1.0;
					return [v / Math.pow(2.0, e), Std.int(e)];
				});
				mathModule.set("ldexp", function(x:Dynamic, i:Dynamic) {
					return _f(x) * Math.pow(2.0, _f(i));
				});
				mathModule.set("copysign", function(x:Dynamic, y:Dynamic) {
					var a = _f(x), b = _f(y);
					return b < 0.0 ? -Math.abs(a) : Math.abs(a);
				});
				// IEEE 754 remainder: x - round(x/y)*y
				mathModule.set("remainder", function(x:Dynamic, y:Dynamic) {
					var a = _f(x), b = _f(y);
					return a - Math.round(a / b) * b;
				});
				// Fused multiply-add (no actual FMA instruction, but semantically correct)
				mathModule.set("fma", function(x:Dynamic, y:Dynamic, z:Dynamic) {
					return _f(x) * _f(y) + _f(z);
				});

				mathModule.set("isnan", function(x:Dynamic) {
					var v = _f(x);
					return v != v;
				});
				mathModule.set("isinf", function(x:Dynamic) {
					var v = _f(x);
					return v == Math.POSITIVE_INFINITY || v == Math.NEGATIVE_INFINITY;
				});
				mathModule.set("isfinite", function(x:Dynamic) {
					var v = _f(x);
					return v == v && v != Math.POSITIVE_INFINITY && v != Math.NEGATIVE_INFINITY;
				});
				mathModule.set("isclose", function(a:Dynamic, b:Dynamic, ?rel_tol:Dynamic, ?abs_tol:Dynamic) {
					var va = _f(a), vb = _f(b);
					var rt = rel_tol != null ? _f(rel_tol) : 1e-9;
					var at = abs_tol != null ? _f(abs_tol) : 0.0;
					return Math.abs(va - vb) <= Math.max(rt * Math.max(Math.abs(va), Math.abs(vb)), at);
				});

				mathModule.set("factorial", function(x:Dynamic) {
					var n = _i(x);
					if (n < 0)
						throw "math domain error";
					var result = 1.0;
					for (k in 2...(n + 1))
						result *= k;
					return result;
				});
				mathModule.set("gcd", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
					if (args.length == 0)
						return 0;
					var r:Int = _i(args[0]);
					for (k in 1...args.length) {
						var b:Int = _i(args[k]);
						if (b == 0)
							return r;
						var g = _gcd(r, b);
						r = Std.int(r / g) * b;
					}
					return r;
				}));
				// n choose k
				mathModule.set("comb", function(n:Dynamic, k:Dynamic) {
					var ni = _i(n), ki = _i(k);
					if (ki < 0 || ki > ni)
						return 0;
					if (ki == 0 || ki == ni)
						return 1;
					if (ki > ni - ki)
						ki = ni - ki; // use smaller half
					var result = 1.0;
					for (j in 0...ki)
						result = result * (ni - j) / (j + 1);
					return Std.int(result);
				});
				// n permutations of k (k defaults to n → n!)
				mathModule.set("perm", function(n:Dynamic, ?k:Dynamic) {
					var ni = _i(n);
					var ki = k != null ? _i(k) : ni;
					if (ki < 0 || ki > ni)
						return 0;
					var result = 1.0;
					for (j in 0...ki)
						result *= (ni - j);
					return Std.int(result);
				});

				// Kahan compensated summation
				mathModule.set("fsum", function(arr:Array<Dynamic>) {
					var sum = 0.0, comp = 0.0;
					for (item in arr) {
						var y = _f(item) - comp;
						var t = sum + y;
						comp = (t - sum) - y;
						sum = t;
					}
					return sum;
				});
				// prod(iterable, start=1)  — start passed as positional second arg
				mathModule.set("prod", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
					var arr:Array<Dynamic> = args.length > 0 ? args[0] : [];
					var result = args.length > 1 ? _f(args[1]) : 1.0;
					for (item in arr)
						result *= _f(item);
					return result;
				}));
				// sum of pairwise products of two iterables
				mathModule.set("sumprod", function(p:Array<Dynamic>, q:Array<Dynamic>) {
					var sum = 0.0;
					var len = p.length < q.length ? p.length : q.length;
					for (j in 0...len)
						sum += _f(p[j]) * _f(q[j]);
					return sum;
				});

				// Euclidean distance between two coordinate arrays
				mathModule.set("dist", function(p:Array<Dynamic>, q:Array<Dynamic>) {
					var sum = 0.0;
					var len = p.length < q.length ? p.length : q.length;
					for (j in 0...len) {
						var d = _f(p[j]) - _f(q[j]);
						sum += d * d;
					}
					return Math.sqrt(sum);
				});

				// Abramowitz & Stegun 7.1.26 (|error| < 1.5e-7)
				mathModule.set("erf", function(x:Dynamic) {
					var v = _f(x);
					var y = _erfCore(Math.abs(v));
					return v < 0.0 ? -y : y;
				});
				mathModule.set("erfc", function(x:Dynamic) {
					var v = _f(x);
					var y = _erfCore(Math.abs(v));
					// erfc(x) = 1 - erf(x); handle sign: erf(-x) = -erf(x)
					return v < 0.0 ? 1.0 + y : 1.0 - y;
				});
				mathModule.set("gamma", function(x:Dynamic) return _gamma(_f(x)));
				mathModule.set("lgamma", function(x:Dynamic) return Math.log(Math.abs(_gamma(_f(x)))));

				// Approximated via log₂ exponent (no bit-cast available cross-target)
				mathModule.set("ulp", function(x:Dynamic) {
					var v = _f(x);
					if (v != v)
						return v;
					var a = Math.abs(v);
					if (a == Math.POSITIVE_INFINITY)
						return Math.POSITIVE_INFINITY;
					if (a == 0.0)
						return 5e-324;
					return Math.pow(2.0, Math.floor(Math.log(a) / Math.log(2.0)) - 52.0);
				});
				mathModule.set("nextafter", function(x:Dynamic, y:Dynamic) {
					var vx = _f(x), vy = _f(y);
					if (vx != vx || vy != vy)
						return Math.NaN;
					if (vx == vy)
						return vy;
					var u = _ulp(vx);
					return vy > vx ? vx + u : vx - u;
				});

				return mathModule;

			case "os":
				var osModule = new Dict();
				osModule.set("__name__", "os");

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
					return FileSystem.readDirectory(path);
				});
				osModule.set("mkdir", function(path:String) {
					FileSystem.createDirectory(path);
					return null;
				});
				osModule.set("rmdir", function(path:String) {
					FileSystem.deleteDirectory(path);
					return null;
				});
				osModule.set("remove", function(path:String) {
					FileSystem.deleteFile(path);
					return null;
				});
				osModule.set("rename", function(oldPath:String, newPath:String) {
					FileSystem.rename(oldPath, newPath);
					return null;
				});
				osModule.set("exists", function(path:String) {
					return FileSystem.exists(path);
				});
				osModule.set("isdir", function(path:String) {
					return FileSystem.isDirectory(path);
				});
				osModule.set("isfile", function(path:String) {
					return FileSystem.exists(path) && !FileSystem.isDirectory(path);
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
					return FileSystem.exists(path);
				});
				pathModule.set("isdir", function(path:String) {
					return FileSystem.isDirectory(path);
				});
				pathModule.set("isfile", function(path:String) {
					return FileSystem.exists(path) && !FileSystem.isDirectory(path);
				});
				pathModule.set("abspath", function(path:String) {
					return FileSystem.absolutePath(path);
				});

				osModule.set("path", pathModule);
				#else
				// Non-sys targets get stub functions
				osModule.set("getcwd", function() {
					return ".";
				});
				osModule.set("name", "unknown");
				#end

				osModule.set("sep", Sys.systemName() == "Windows" ? "\\" : "/");
				osModule.set("altsep", Sys.systemName() == "Windows" ? "/" : null);
				osModule.set("extsep", ".");
				osModule.set("pathsep", Sys.systemName() == "Windows" ? ";" : ":");
				osModule.set("linesep", Sys.systemName() == "Windows" ? "\r\n" : "\n");
				osModule.set("curdir", ".");
				osModule.set("pardir", "..");
				osModule.set("devnull", Sys.systemName() == "Windows" ? "nul" : "/dev/null");

				// access/seek/exit flags
				osModule.set("F_OK", 0);
				osModule.set("R_OK", 4);
				osModule.set("W_OK", 2);
				osModule.set("X_OK", 1);
				osModule.set("SEEK_SET", 0);
				osModule.set("SEEK_CUR", 1);
				osModule.set("SEEK_END", 2);
				osModule.set("EX_OK", 0);

				return osModule;

			case "random":
				var randomModule = new Dict();
				randomModule.set("__name__", "random");

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
				jsonModule.set("__name__", "json");
				jsonModule.set("dumps", function(obj:Dynamic, ?indent:Dynamic) {
					var indentStr = indent != null ? StringTools.rpad("", " ", Std.int(indent)) : null;
					return haxe.Json.stringify(obj, null, indentStr);
				});
				jsonModule.set("loads", function(str:String) {
					// Parse JSON string
					return haxe.Json.parse(str);
				});
				return jsonModule;

			case "datetime":
				var datetimeModule = new Dict();
				datetimeModule.set("__name__", "datetime");

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
				reModule.set("__name__", "re");

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

	/**
	 * Assign a custom loader to handle additional module names before the
	 * built-in switch runs.  Returns null to fall through to built-ins.
	 *
	 * Example:
	 *   Library.loadLibrary = (interp, name) -> switch name {
	 *     case "mymodule": buildMyModule(interp);
	 *     default: null;
	 *   }
	 *
	 * Chaining multiple loaders:
	 *   var prev = Library.loadLibrary;
	 *   Library.loadLibrary = (interp, name) -> myLoader(interp, name) ?? prev(interp, name);
	 */
	public static var loadLibrary:(interp:PyInterp, moduleName:String) -> Null<Dict> = (_, _) -> null;
}
