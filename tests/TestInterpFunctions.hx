import haxe.unit.TestCase;
import hython.PythonParser;
import hython.Interp;

class TestInterpFunctions extends TestCase {
	function run(code:String):Dynamic {
		var p = new PythonParser();
		var expr = p.parseString(code);
		return new Interp().execute(expr);
	}

	public function testFunctionCall() {
		assertEquals(5, run("def add(a, b):\n    return a + b\nadd(2, 3)"));
	}

	public function testClosure() {
		assertEquals(8, run("def makeAdder(x):\n    def add(y):\n        return x + y\n    return add\nf = makeAdder(5)\nf(3)"));
	}

	public function testOptionalParams() {
		assertEquals(3, run("def f(a, b):\n    if b == None:\n        return a\n    return a + b\nf(3, None)"));
	}
}
