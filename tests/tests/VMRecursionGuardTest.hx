package tests.tests;

import paopao.hython.*;
import tests.unit.TestCase;

class VMRecursionGuardTest extends TestCase {
	public function new() {
		super();
	}

	public function testInfiniteRecursionThrowsRecursionGuardError():Void {
		try {
			executeSource("
def loop():
    return loop()

result = loop()
");
			fail("Expected recursion guard error");
		} catch (e:Error) {
			assertEquals("RecursionError", e.errorName());
			assertEquals("maximum recursion depth exceeded", e.errorMessage());
		}
	}

	private function executeSource(source:String):VM {
		var vm = new VM();
		var lexer = new Lexer(source);
		var tokens = lexer.tokenize();
		var program = new Parser(tokens, lexer.tokenPositions).parse();
		new Semantic().analyze(program, "<test>");
		var code = new Compiler().compile(program);
		vm.execute(code);
		return vm;
	}
}
