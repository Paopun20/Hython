package paopao.hython.utils;

#if cpp
import cpp.ObjectType;
#end

@:analyzer(ignore, no_optimize)
class UnsafeReflect {
	public #if !cpp inline #end static function hasField(o:Dynamic, field:String):Bool {
		#if cpp untyped {
			return o.__HasField(field);
		}
		#else
		return Reflect.hasField(o, field);
		#end
	}

	public #if !cpp inline #end static function field(o:Dynamic, field:String):Dynamic {
		#if cpp untyped {
			return o.__Field(field, untyped __cpp__("::hx::paccNever"));
		}
		#else
		return Reflect.field(o, field);
		#end
	}

	public #if !cpp inline #end static function setField(o:Dynamic, field:String, value:Dynamic):Void {
		#if cpp untyped {
			o.__SetField(field, value, untyped __cpp__("::hx::paccNever"));
		}
		#else
		return Reflect.setField(o, field, value);
		#end
	}

	public #if !cpp inline #end static function getProperty(o:Dynamic, field:String):Dynamic {
		#if cpp untyped {
			return o.__Field(field, untyped __cpp__("::hx::paccAlways"));
		}
		#else
		return Reflect.getProperty(o, field);
		#end
	}

	public #if !cpp inline #end static function setProperty(o:Dynamic, field:String, value:Dynamic):Void {
		#if cpp untyped {
			o.__SetField(field, value, untyped __cpp__("::hx::paccAlways"));
		}
		#else
		Reflect.setProperty(o, field, value);
		#end
	}

	public #if !cpp inline #end static function callFieldUnsafe(o:Dynamic, field:String, args:Array<Dynamic>):Dynamic {
		#if cpp untyped {
			var func:Dynamic = o.__Field(field, untyped __cpp__("::hx::paccDynamic"));
			untyped func.__SetThis(o);
			return untyped func.__Run(args);
		}
		#else
		return Reflect.callMethod(o, Reflect.field(o, field), args);
		#end
	}

	public inline static function callMethod(o:Dynamic, func:haxe.Constraints.Function, args:Array<Dynamic>):Dynamic {
		return Reflect.callMethod(o, func, args);
	}

	public #if !cpp inline #end static function callMethodSafe(o:Dynamic, func:haxe.Constraints.Function, args:Array<Dynamic>):Dynamic {
		#if cpp untyped {
			if (func == null)
				throw cpp.ErrorConstants.nullFunctionPointer;
			untyped func.__SetThis(o);
			return untyped func.__Run(args);
		}
		#else
		return Reflect.callMethod(o, func, args);
		#end
	}

	public #if !cpp inline #end static function callMethodUnsafe(o:Dynamic, func:haxe.Constraints.Function, args:Array<Dynamic>):Dynamic {
		#if cpp untyped {
			untyped func.__SetThis(o);
			return untyped func.__Run(args);
		}
		#else
		return Reflect.callMethod(o, func, args);
		#end
	}

	public inline static function fields(o:Dynamic):Array<String>
		return Reflect.fields(o);

	/*untyped {
		if (o == null)
			return new Array();
		var a:Array<String> = [];
		o.__GetFields(a);
		return a;
	}*/
	public #if !cpp inline #end static function isFunction(f:Dynamic):Bool
		#if cpp untyped {
			return f.__GetType() == ObjectType.vtFunction;
		}
		#else
		return Reflect.isFunction(f);
		#end

	public inline static function compare<T>(a:T, b:T):Int {
		return Reflect.compare(a, b);
		// return (a == b) ? 0 : (((a : Dynamic) > (b : Dynamic)) ? 1 : -1);
	}

	public inline static function compareMethods(f1:Dynamic, f2:Dynamic):Bool {
		return Reflect.compareMethods(f1, f2);
	}

	public #if !cpp inline #end static function isObject(v:Dynamic):Bool {
		#if cpp untyped {
			var t:Int = v.__GetType();
			return t == ObjectType.vtObject || t == ObjectType.vtClass || t == ObjectType.vtString || t == ObjectType.vtArray;
		}
		#else
		return Reflect.isObject(v);
		#end
	}

	public #if !cpp inline #end static function isEnumValue(v:Dynamic):Bool {
		#if cpp untyped {
			return v.__GetType() == ObjectType.vtEnum;
		}
		#else
		return Reflect.isEnumValue(v);
		#end
	}

	public #if !cpp inline #end static function deleteField(o:Dynamic, field:String):Bool {
		#if cpp untyped {
			return untyped __global__.__hxcpp_anon_remove(o, field);
		}
		#else
		return Reflect.deleteField(o, field);
		#end
	}

	public #if !cpp inline #end static function copy<T>(o:Null<T>):Null<T> {
		#if cpp
		if (o == null)
			return null;
		var t:Int = untyped o.__GetType();
		if (t == ObjectType.vtString)
			return o;
		if (t == ObjectType.vtArray)
			return untyped o.__Field("copy", untyped __cpp__("::hx::paccDynamic"))();
		var o2:Dynamic = {};
		for (f in UnsafeReflect.fields(o))
			UnsafeReflect.setField(o2, f, UnsafeReflect.field(o, f));
		return o2;
		#else
		return Reflect.copy(o);
		#end
	}

	@:overload(function(f:Array<Dynamic>->Void):Dynamic {})
	public static function makeVarArgs(f:Array<Dynamic>->Dynamic):Dynamic {
		#if cpp
		return untyped __global__.__hxcpp_create_var_args(f);
		#else
		return inline Reflect.makeVarArgs(f);
		#end
	}
}
