import haxe.unit.TestCase;
import hython.Parser;
import hython.Interp;

class TestInterpControlFlow extends TestCase {
	function run(code:String):Dynamic {
		var p = new Parser();
		var expr = p.parseString(code);
		return new Interp().execute(expr);
	}

	public function testWhileLoop() {
		assertEquals(10, run("
			var i = 0;
			var sum = 0;
			while (i < 5) {
				sum += i;
				i++;
			}
			sum;
		"));
	}

	public function testForLoop() {
		assertEquals(6, run("
			var sum = 0;
			for (i in 0...4) {
				sum += i;
			}
			sum;
		"));
	}

	public function testBreakContinue() {
		assertEquals(4, run("
			var i = 0;
			var sum = 0;
			while (true) {
				i++;
				if (i == 3) continue;
				if (i == 5) break;
				sum += i;
			}
			sum;
		"));
	}
}
