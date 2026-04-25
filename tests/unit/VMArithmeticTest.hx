package tests.unit;

import paopao.hython.Compiler;
import paopao.hython.Lexer;
import paopao.hython.Parser;
import paopao.hython.Semantic;
import paopao.hython.VM;
import tests.unit.TestCase;

class VMArithmeticTest extends TestCase {
	public function new() {
		super();
	}

	public function testFloatMinusIntUsesSubtraction():Void {
		var vm = executeSource("result = 5.5 - 2");
		assertEquals(3.5, vm.toHaxe(vm.getGlobal("result")));
	}

	private function executeSource(source:String):VM {
		var vm = new VM();
		var tokens = new Lexer(source).tokenize();
		var program = new Parser(tokens).parse();
		new Semantic().analyze(program);
		var code = new Compiler().compile(program);
		vm.execute(code);
		return vm;
	}
}
