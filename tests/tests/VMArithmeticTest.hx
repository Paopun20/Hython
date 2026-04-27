package tests.tests;

import paopao.hython.*;
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

	public function testComparisonOperatorsEvaluateCorrectly():Void {
		var vm = executeSource("lt = 1 < 2
gt = 2 > 1
lte = 2 <= 2
gte = 3 >= 2
eq = 4 == 4
neq = 4 != 5
");
		assertEquals(true, vm.toHaxe(vm.getGlobal("lt")));
		assertEquals(true, vm.toHaxe(vm.getGlobal("gt")));
		assertEquals(true, vm.toHaxe(vm.getGlobal("lte")));
		assertEquals(true, vm.toHaxe(vm.getGlobal("gte")));
		assertEquals(true, vm.toHaxe(vm.getGlobal("eq")));
		assertEquals(true, vm.toHaxe(vm.getGlobal("neq")));
	}

	public function testComparisonPrecedenceIsLowerThanArithmetic():Void {
		var vm = executeSource("result = 1 + 2 <= 3");
		assertEquals(true, vm.toHaxe(vm.getGlobal("result")));
	}

	public function testChainedComparisonTrue():Void {
		var vm = executeSource("result = 1 < 2 < 3");
		assertEquals(true, vm.toHaxe(vm.getGlobal("result")));
	}

	public function testChainedComparisonFalse():Void {
		var vm = executeSource("result = 1 < 2 > 3");
		assertEquals(false, vm.toHaxe(vm.getGlobal("result")));
	}


	public function testForInRangeAccumulatesValues():Void {
		var vm = executeSource("result = 0
for i in range(5):
    result = result + i
");
		assertEquals(10, vm.toHaxe(vm.getGlobal("result")));
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
