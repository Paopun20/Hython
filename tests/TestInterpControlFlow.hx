import tool.unit.TestCase;
import paopao.hython.Parser;
import paopao.hython.Interp;

class TestInterpControlFlow extends TestCase {
	function run(code:String):Dynamic {
		var p = new Parser();
		var expr = p.parseString(code);
		return new Interp().execute(expr);
	}

	public function testWhileLoop() {
		assertEquals(10, run("i = 0\nsum = 0\nwhile i < 5:\n    sum += i\n    i += 1\nsum"));
	}

	public function testForLoop() {
		assertEquals(6, run("sum = 0\nfor i in range(0, 4):\n    sum += i\nsum"));
	}

	public function testBreakContinue() {
		assertEquals(7, run("i = 0\nsum = 0\nwhile True:\n    i += 1\n    if i == 3:\n        continue\n    if i == 5:\n        break\n    sum += i\nsum"));
	}
}
