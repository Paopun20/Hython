import haxe.unit.TestCase;
import hython.Parser;
import hython.Interp;

class TestPythonSyntax extends TestCase {
	function run(code:String):Dynamic {
		var p = new Parser();
		var expr = p.parseString(code);
		return new Interp().execute(expr);
	}

	public function testSimpleFunction() {
		assertEquals(15, run("def greet():\n    return 15\ngreet()"));
	}

	public function testFunctionWithArgs() {
		assertEquals(8, run("def add(a, b):\n    return a + b\nadd(3, 5)"));
	}

	public function testNestedFunction() {
		assertEquals(42, run("def outer():\n    def inner():\n        return 42\n    return inner()\nouter()"));
	}

	public function testIfStatement() {
		assertEquals(100, run("x = 10\nif x > 5:\n    result = 100\nelse:\n    result = 50\nresult"));
	}

	public function testElifStatement() {
		assertEquals(2, run("x = 5\nif x < 0:\n    y = 1\nelif x < 10:\n    y = 2\nelse:\n    y = 3\ny"));
	}

	public function testWhileLoop() {
		assertEquals(10, run("i = 0\nsum = 0\nwhile i < 5:\n    sum += i\n    i += 1\nsum"));
	}

	public function testForLoopWithRange() {
		assertEquals(6, run("total = 0\nfor i in range(4):\n    total += i\ntotal"));
	}

	public function testListLiteral() {
		var result = run("items = [1, 2, 3, 4, 5]\nitems");
		assertTrue(Std.isOfType(result, Array));
	}

	public function testDictionaryLiteral() {
		var result = run("person = {'name': 'Alice', 'age': 30}\nperson");
		assertTrue(result != null);
	}

	public function testBooleanLogic() {
		assertEquals(true, run("x = 5\nif x > 0 and x < 10:\n    result = True\nelse:\n    result = False\nresult == True"));
	}

	public function testNoneValue() {
		var result = run("x = None\nx");
		assertEquals(null, result);
	}

	public function testStringOperations() {
		var result = run("text = \"hello\"\ntext");
		assertEquals("hello", result);
	}

	public function testLambdaFunction() {
		assertEquals(7, run("add = lambda a: a + 2\nadd(5)"));
	}

	public function testPrintFunction() {
		// Just verify it doesn't error
		run("print(\"Hello, World!\")");
		assertTrue(true);
	}

	public function testComplexProgram() {
		assertEquals(120, run("def factorial(n):\n    if n <= 1:\n        return 1\n    return n * factorial(n - 1)\nfactorial(5)"));
	}
}
