package haxe.unit;

class TestCase {
	public function new() {}

	public function assertEquals<T>(expected:T, actual:T, ?msg:String):Void {
		if (expected != actual) {
			throw "Assertion failed: expected " + expected + " but got " + actual + (msg != null ? " (" + msg + ")" : "");
		}
	}

	public function assertTrue(condition:Bool, ?msg:String):Void {
		if (!condition) {
			throw "Assertion failed: condition was false" + (msg != null ? " (" + msg + ")" : "");
		}
	}

	public function assertFalse(condition:Bool, ?msg:String):Void {
		if (condition) {
			throw "Assertion failed: condition was true" + (msg != null ? " (" + msg + ")" : "");
		}
	}
}
