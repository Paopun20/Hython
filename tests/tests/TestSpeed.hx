package tests.tests;

import paopao.hython.*;
import tests.unit.TestCase;
import haxe.Timer;

class TestSpeed extends TestCase {
	public function testSpeedForLoop() {
		var source = "
x = 0
for i in range(1000000):
    x = x + i
";

		var code = compile(source);
		var time = runBenchmark(code, 10);

		trace("Avg Time: " + time + " seconds");
	}

	public function testSpeedFib() {
		var source = "
def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

result = fib(25)
";

		var code = compile(source);
		var time = runBenchmark(code, 10);

		trace("Avg Time: " + time + " seconds");
	}

	private function runBenchmark(code:Dynamic, iterations:Int):Float {
		var vm = new VM();

		// warmup
		vm.execute(code);

		var start = Timer.stamp();
		for (i in 0...iterations) {
			vm.execute(code);
		}
		var end = Timer.stamp();

		return (end - start) / iterations;
	}

	private function compile(source:String):Dynamic {
		var lexer = new Lexer(source);
		var tokens = lexer.tokenize();
		var program = new Parser(tokens, lexer.tokenPositions).parse();
		new Semantic().analyze(program, "<test>", new VM().getSemanticBindings());
		return new Compiler().compile(program);
	}
}
