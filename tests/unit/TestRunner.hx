package tests.unit;

import tests.unit.TestCase;
import haxe.CallStack;

class TestRunner {
	private static inline var DEFAULT_TIMEOUT_SECONDS:Float = 5.0;

	private var tests:Array<TestCase> = [];
	private var passed:Int = 0;
	private var failed:Int = 0;
	private var timeoutSeconds:Float;
	public var useThread: Bool = true;

	public function new(useThread: Bool = true, timeoutSeconds:Float = DEFAULT_TIMEOUT_SECONDS) {
		this.timeoutSeconds = timeoutSeconds;
		this.useThread = useThread;
	}

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
		var testClassName = Type.getClassName(Type.getClass(test));
		var fields = Type.getInstanceFields(Type.getClass(test));
		fields.sort(Reflect.compare);

		for (field in fields) {
			if (field.indexOf("test") != 0)
				continue;

			var fn = Reflect.field(test, field);
			if (!Reflect.isFunction(fn))
				continue;

			runTestMethod(test, fn, testClassName, field);
		}
	}

	private function runTestMethod(test:TestCase, fn:Dynamic, testClassName:String, methodName:String):Void {
		#if sys
		if (useThread) {
			runWithTimeout(test, fn, testClassName, methodName);
		} else {
			runDirect(test, fn, testClassName, methodName);
		}
		#else
		runDirect(test, fn, testClassName, methodName);
		#end
	}

	#if sys
	private function runWithTimeout(test:TestCase, fn:Dynamic, testClassName:String, methodName:String):Void {
		var lock = new sys.thread.Lock();
		var outcome:TestOutcome = Pending;

		sys.thread.Thread.create(() -> {
			try {
				Reflect.callMethod(test, fn, []);
				outcome = Passed;
			} catch (e:Dynamic) {
				outcome = Failed(e, CallStack.exceptionStack(true));
			}
			lock.release();
		});

		var completedBeforeTimeout = lock.wait(timeoutSeconds);

		if (!completedBeforeTimeout) {
			failed++;
			trace('FAIL $testClassName.$methodName: timed out after ${timeoutSeconds}s');
			return;
		}

		recordOutcome(outcome, testClassName, methodName);
	}
	#end

	private function runDirect(test:TestCase, fn:Dynamic, testClassName:String, methodName:String):Void {
		var outcome:TestOutcome;
		try {
			Reflect.callMethod(test, fn, []);
			outcome = Passed;
		} catch (e:Dynamic) {
			outcome = Failed(e, CallStack.exceptionStack(true));
		}
		recordOutcome(outcome, testClassName, methodName);
	}

	private function recordOutcome(outcome:TestOutcome, testClassName:String, methodName:String):Void {
		switch (outcome) {
			case Passed:
				passed++;
				trace('OK $testClassName.$methodName');

			case Failed(error, stack):
				failed++;
				trace('FAIL $testClassName.$methodName: $error');
				trace(formatStack(error, stack));

			case Pending:
				// Should never happen — outcome is always set before lock.release()
		}
	}

	private function formatStack(error:Dynamic, stack:Array<StackItem>):String {
		var lines = ['\nError: $error'];
		var index = 0;

		for (item in stack) {
			switch (item) {
				case FilePos(_, file, line, _):
					lines.push('#$index $file:$line');
				default:
					lines.push('#$index ${Std.string(item)}');
			}
			index++;
		}

		return lines.join('\n');
	}
}

private enum TestOutcome {
	Pending;
	Passed;
	Failed(error:Dynamic, stack:Array<StackItem>);
}
