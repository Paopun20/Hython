import tests.unit.TestRunner;
import tests.*;

class TestMain {
	static function main() {
		var runner = new TestRunner();
		runner.add(new LexerTest());
		runner.add(new ParserTest());
		runner.add(new InterpTest());
		runner.run();
	}
}