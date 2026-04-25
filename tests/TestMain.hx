package;

import tests.unit.TestRunner;
import tests.unit.VMArithmeticTest;

class TestMain {
	static function main() {
		var runner = new TestRunner();
		runner.add(new VMArithmeticTest());

		if (!runner.run()) {
			Sys.exit(1);
		}
	}
}
