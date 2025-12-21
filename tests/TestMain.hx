class TestMain {
	static function main() {
		var runner = new haxe.unit.TestRunner();
		runner.add(new TestInterpBasics());
		runner.add(new TestInterpFunctions());
		runner.add(new TestInterpControlFlow());
		runner.run();
	}
}
