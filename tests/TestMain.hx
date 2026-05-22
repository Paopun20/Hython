package;

import tests.unit.TestRunner;
import tests.tests.*;

class TestMain {
	static function main() {
		var runner = new TestRunner(true);
		runner.add(new Test1());

		if (!runner.run()) {
			Sys.exit(1);
		}
	}
}
