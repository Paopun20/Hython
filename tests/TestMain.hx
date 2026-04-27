package;

import tests.unit.TestRunner;
import tests.tests.*;

class TestMain {
	static function main() {
		var runner = new TestRunner();
		runner.add(new VMArithmeticTest());
		runner.add(new SemanticErrorPositionTest());
		runner.add(new TestHaxeNative());
		runner.add(new TestSpeed());

		if (!runner.run()) {
			Sys.exit(1);
		}
	}
}
