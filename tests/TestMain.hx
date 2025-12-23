import tests.unit.TestRunner;

class TestMain {
	static function main() {
		var runner = new TestRunner();
		runner.add(new TestInterpBasics());
		runner.add(new TestInterpFunctions());
		runner.add(new TestInterpControlFlow());
		runner.add(new TestPythonSyntax());
		runner.add(new TestBuiltins());
		runner.add(new TestInjector());
		runner.run();
	}
}
