package tests.tests;

import paopao.hython.*;
import tests.unit.TestCase;

import haxe.Timer;

class TestSpeed extends TestCase {
    public function testSpeed1() {
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

	private function executeInto(vm:VM, source:String):Void {
		var lexer = new Lexer(source);
		var tokens = lexer.tokenize();
		var program = new Parser(tokens, lexer.tokenPositions).parse();
		new Semantic().analyze(program, "<test>", vm.getSemanticBindings());
		var code = new Compiler().compile(program);
		vm.execute(code);
	}
}