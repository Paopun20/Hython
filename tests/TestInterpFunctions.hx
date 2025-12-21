import haxe.unit.TestCase;
import hython.Parser;
import hython.Interp;

class TestInterpFunctions extends TestCase {
	function run(code:String):Dynamic {
		var p = new Parser();
		var expr = p.parseString(code);
		return new Interp().execute(expr);
	}

	public function testFunctionCall() {
		assertEquals(5, run("
			function add(a, b) {
				return a + b;
			}
			add(2, 3);
		"));
	}

	public function testClosure() {
		assertEquals(8, run("
			function makeAdder(x) {
				function add(y) {
					return x + y;
				}
				return add;
			}
			var f = makeAdder(5);
			f(3);
		"));
	}

	public function testOptionalParams() {
		assertEquals(3, run("
			function f(a, b = null) {
				if (b == null) return a;
				return a + b;
			}
			f(3);
		"));
	}
}
