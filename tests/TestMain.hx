package;

import tests.unit.TestRunner;
import tests.unit.SemanticErrorPositionTest;
import tests.unit.VMArithmeticTest;

class TestMain {
	static function main() {
		var runner = new TestRunner();
		runner.add(new VMArithmeticTest());
		runner.add(new SemanticErrorPositionTest());

		if (!runner.run()) {
			Sys.exit(1);
		}
	}
}
