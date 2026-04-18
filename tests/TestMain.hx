import tests.unit.TestRunner;
import tests.*;
import tests.tests.TestName;
import tests.tests.TestPerformance;

class TestMain {
	static function main() {
		var runner = new TestRunner();
		
		// runner.add(new TestName());
		runner.add(new TestPerformance());

		runner.run();
	}
}