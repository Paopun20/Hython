package tests.tests;

import paopao.hython.*;
import tests.unit.TestCase;
import haxe.Timer;

class TestSpeed extends TestCase {
	public function testSpeedForLoop() {
		var vm = new VM();
		var start = Timer.stamp();

		executeInto(vm, "
x = 0
for i in range(1000000):
    x = x + i
");

		var end = Timer.stamp();
		trace("Time: " + (end - start) + " seconds");
	}

	public function testSpeedX() {
		var vm = new VM();
		var start = Timer.stamp();

		var source = "
def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

result = fib(25)
";

		executeInto(vm, source);

		var end = Timer.stamp();
		trace("Time: " + (end - start) + " seconds");
	}

	private function executeInto(vm:VM, source:String):Void {
		var lexer = new Lexer(source);
		var tokens = lexer.tokenize();
		var program = new Parser(tokens, lexer.tokenPositions).parse();
		new Semantic().analyze(program, "<test>", vm.getSemanticBindings());
		var code = new Compiler().compile(program);
		vm.execute(code);
	}
}
