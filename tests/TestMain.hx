class TestMain {
	static function main() {
		var runner = new tool.unit.TestRunner();
		runner.add(new TestInterpBasics());
		runner.add(new TestInterpFunctions());
		runner.add(new TestInterpControlFlow());
		runner.add(new TestPythonSyntax());
		runner.run();
	}
}
