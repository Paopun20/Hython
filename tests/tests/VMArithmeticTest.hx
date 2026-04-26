package tests.tests;

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

	public function testIntPlusFloatProducesFloat():Void {
		var vm = executeSource("result = 2 + 3.5");
		assertEquals(5.5, vm.toHaxe(vm.getGlobal("result")));
	}

	public function testMultiplicationHasHigherPrecedenceThanAddition():Void {
		var vm = executeSource("result = 2 + 3 * 4");
		assertEquals(14, vm.toHaxe(vm.getGlobal("result")));
	}

	public function testParenthesesOverrideDefaultPrecedence():Void {
		var vm = executeSource("result = (2 + 3) * 4");
		assertEquals(20, vm.toHaxe(vm.getGlobal("result")));
	}

	public function testIntegerDivisionReturnsFloat():Void {
		var vm = executeSource("result = 7 / 2");
		assertEquals(3.5, vm.toHaxe(vm.getGlobal("result")));
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
