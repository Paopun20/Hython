import tests.unit.TestCase;
import paopao.hython.Parser;
import paopao.hython.Interp;

/**
 * This test is for a specific bug that a user reported. It's not meant to be a general test of any particular feature, but just to make sure that this specific code doesn't throw an error anymore.
 */
class TestUserBug extends TestCase {
	function run(code:String):Dynamic {
		var p = new Parser();
		var expr = p.parseString(code);
		return new Interp().execute(expr);
	}

	function testBug1() {
		var result = run("
import random

def main():
	rand = random.randint(0, 4)
	print('intro/cpuhead/normal/' + str(rand) + '')

main()
");
		assertTrue(result == null); // The test is just that it doesn't throw an error
	}
}
