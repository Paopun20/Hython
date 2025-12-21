package haxe.unit;

class TestRunner {
	private var tests:Array<TestCase> = [];
	private var passed:Int = 0;
	private var failed:Int = 0;

	public function new() {}

	public function add(test:TestCase):Void {
		tests.push(test);
	}

	public function run():Bool {
		for (test in tests) {
			runTest(test);
		}

		trace('Tests passed: $passed');
		trace('Tests failed: $failed');

		return failed == 0;
	}

	private function runTest(test:TestCase):Void {
		var testClass = Type.getClassName(Type.getClass(test));
		var fields = Type.getInstanceFields(Type.getClass(test));

		for (field in fields) {
			if (field.indexOf("test") == 0) {
				try {
					Reflect.callMethod(test, Reflect.field(test, field), []);
					passed++;
					trace('✓ $testClass.$field');
				} catch (e:Dynamic) {
					failed++;
					trace('✗ $testClass.$field: $e');
				}
			}
		}
	}
}
