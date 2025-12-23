package tests.unit;

class TestCase {
	public function new() {}

	public function assertEquals<T>(expected:T, actual:T, ?msg:String):Void {
		if (!deepEquals(expected, actual)) {
			throw "Assertion failed: expected " + Std.string(expected)
				+ " but got " + Std.string(actual)
				+ (msg != null ? " (" + msg + ")" : "");
		}
	}

	function deepEquals(a:Dynamic, b:Dynamic):Bool {
		if (a == b) return true;
		if (a == null || b == null) return false;

		// Array
		if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
			var aa:Array<Dynamic> = cast a;
			var bb:Array<Dynamic> = cast b;
			if (aa.length != bb.length) return false;
			for (i in 0...aa.length)
				if (!deepEquals(aa[i], bb[i])) return false;
			return true;
		}

		// Object / anonymous structure
		if (Type.typeof(a) == TObject && Type.typeof(b) == TObject) {
			for (field in Reflect.fields(a)) {
				if (!Reflect.hasField(b, field)) return false;
				if (!deepEquals(Reflect.field(a, field), Reflect.field(b, field)))
					return false;
			}
			return Reflect.fields(a).length == Reflect.fields(b).length;
		}

		return false;
	}

	public function assertTrue(condition:Bool, ?msg:String):Void {
		if (!condition)
			throw "Assertion failed: condition was false" + (msg != null ? " (" + msg + ")" : "");
	}

	public function assertFalse(condition:Bool, ?msg:String):Void {
		if (condition)
			throw "Assertion failed: condition was true" + (msg != null ? " (" + msg + ")" : "");
	}
}
