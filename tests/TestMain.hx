import tests.unit.TestRunner;
import tests.*;
import tests.tests.TestName;

class TestMain {
	static function main() {
		var runner = new TestRunner();
		
		runner.add(new TestName());

		runner.run();
	}
}