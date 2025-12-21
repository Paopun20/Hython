import haxe.unit.TestCase;
import hython.Parser;
import hython.Interp;

class TestInterpBasics extends TestCase {
	function run(code:String):Dynamic {
		var p = new Parser();
		var expr = p.parseString(code);
		return new Interp().execute(expr);
	}

	public function testMath() {
		assertEquals(3, run("1 + 2"));
		assertEquals(6, run("2 * 3"));
		assertEquals(2, run("5 - 3"));
	}

	public function testVariables() {
		assertEquals(10, run("var x = 10; x;"));
	}

	public function testIfElse() {
		assertEquals(1, run("if (true) 1 else 2"));
		assertEquals(2, run("if (false) 1 else 2"));
	}
}
