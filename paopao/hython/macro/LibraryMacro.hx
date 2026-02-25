package paopao.hython.macro;
import haxe.ds.StringMap;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end
/**
	Usage:
		@:build(paopao.hython.macro.LibraryMacro.register("math"))
		class HythonMath { ... }
	Then in Hython scripts:
		import math
		math.sin(1.0)
	If path is null, the class name is used as the module key.
**/
class LibraryMacro {
	private static var modules:StringMap<Dynamic> = new StringMap();
	
	public static macro function register(?path:String):Array<Field> {
		#if macro
		var fields = Context.getBuildFields();
		var cls = Context.getLocalClass().get();
		var className = cls.name;
		var typePath = cls.pack.concat([className]).join(".");
		// Use the provided path as the module name, fall back to class name
		var moduleKey = (path != null && path != "") ? path : className;
		// At runtime: build a Dict of all public static fields so that
		// `import math` gives a module object where math.sin() etc. work.
		var initExpr = macro {
			var _cls = Type.resolveClass($v{typePath});
			var _mod = new paopao.hython.Objects.Dict();
			for (_field in Type.getClassFields(_cls)) {
				var _val = Reflect.field(_cls, _field);
				_mod.set(_field, _val);
			}
			paopao.hython.macro.LibraryMacro.registerModule($v{moduleKey}, _mod);
		};
		fields.push({
			name: "__hython_register__",
			access: [AStatic, APublic],
			meta: [{name: ":keep", pos: Context.currentPos()}],
			kind: FFun({args: [], ret: macro :Void, expr: initExpr}),
			pos: Context.currentPos()
		});
		// Auto-trigger at static init time
		fields.push({
			name: "__init__",
			access: [AStatic, APrivate],
			kind: FFun({args: [], ret: macro :Void, expr: macro __hython_register__()}),
			pos: Context.currentPos()
		});
		return fields;
		#else
		return null;
		#end
	}
	
	// Public helper method to register modules
	public static function registerModule(name:String, module:Dynamic):Void {
		modules.set(name, module);
		trace("Register ID: " + name);
	}
	
	public static function getLib(name:String):Dynamic {
		return modules.get(name);
	}
}