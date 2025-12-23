package tests.unit;

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
		var cls = Type.getClass(test);
		var testClass = Type.getClassName(cls);
		var fields = Type.getInstanceFields(cls);

		fields.sort(Reflect.compare);

		for (field in fields) {
			if (field.indexOf("test") == 0) {
				var fn = Reflect.field(test, field);
				if (!Reflect.isFunction(fn))
					continue;

				try {
					Reflect.callMethod(test, fn, []);
					passed++;
					// trace('✓ $testClass.$field'); // Test passed
				} catch (e:Dynamic) {
					failed++;
					trace('✗ $testClass.$field: $e'); // Test failed
				}
			}
		}
	}
}
