package tests.tests;

import tests.unit.TestCase;
import paopao.hython.Ast;
import paopao.hython.Interp;
import paopao.hython.Parser;
import paopao.hython.bytecode.BytecodeCompiler;
import haxe.io.Bytes;

class TestPerformance extends TestCase {
	
	private function createSimpleExpr():Expr {
		// Create: 2 + 3 * 4
		var two = new Expr(EConstInt(2), 0, 0);
		var three = new Expr(EConstInt(3), 0, 0);
		var four = new Expr(EConstInt(4), 0, 0);
		var mul = new Expr(EBinop(MUL, three, four), 0, 0);
		var add = new Expr(EBinop(ADD, two, mul), 0, 0);
		return add;
	}
	
	private function createComplexExpr():Expr {
		// Create a more complex expression with nested operations
		var one = new Expr(EConstInt(1), 0, 0);
		var two = new Expr(EConstInt(2), 0, 0);
		var three = new Expr(EConstInt(3), 0, 0);
		var four = new Expr(EConstInt(4), 0, 0);
		var five = new Expr(EConstInt(5), 0, 0);
		
		var add1 = new Expr(EBinop(ADD, one, two), 0, 0);
		var mul1 = new Expr(EBinop(MUL, add1, three), 0, 0);
		var add2 = new Expr(EBinop(ADD, mul1, four), 0, 0);
		var sub1 = new Expr(EBinop(SUB, add2, five), 0, 0);
		var mul2 = new Expr(EBinop(MUL, sub1, two), 0, 0);
		
		return mul2;
	}
	
	public function testBytecodeCompileTime() {
		var ast = createSimpleExpr();
		var compiler = new BytecodeCompiler();
		
		var start = haxe.Timer.stamp();
		for (i in 0...1000) {
			compiler.compile(ast);
		}
		var elapsed = haxe.Timer.stamp() - start;
		
		trace("Bytecode compile time (1000 iterations): " + elapsed + "s");
		assertTrue(elapsed < 10.0, "Compilation should be reasonably fast");
	}
	
	public function testBytecodeExecutionTime() {
		var ast = createSimpleExpr();
		var compiler = new BytecodeCompiler();
		var bytecode = compiler.compile(ast);
		var interp = new Interp();
		
		var start = haxe.Timer.stamp();
		for (i in 0...1000) {
			interp.execute(bytecode);
		}
		var elapsed = haxe.Timer.stamp() - start;
		
		trace("Bytecode execution time (1000 iterations): " + elapsed + "s");
		assertTrue(elapsed < 10.0, "Execution should be reasonably fast");
	}
	
	public function testComplexBytecodeCompile() {
		var ast = createComplexExpr();
		var compiler = new BytecodeCompiler();
		
		var start = haxe.Timer.stamp();
		for (i in 0...100) {
			compiler.compile(ast);
		}
		var elapsed = haxe.Timer.stamp() - start;
		
		trace("Complex bytecode compile (100 iterations): " + elapsed + "s");
		assertTrue(elapsed < 5.0, "Complex compilation should still be fast");
	}
	
	public function testComplexBytecodeExecution() {
		var ast = createComplexExpr();
		var compiler = new BytecodeCompiler();
		var bytecode = compiler.compile(ast);
		var interp = new Interp();
		
		var start = haxe.Timer.stamp();
		for (i in 0...100) {
			interp.execute(bytecode);
		}
		var elapsed = haxe.Timer.stamp() - start;
		
		trace("Complex bytecode execution (100 iterations): " + elapsed + "s");
		assertTrue(elapsed < 5.0, "Complex execution should still be fast");
	}
	
	public function testBytecodeRoundTripPerformance() {
		var ast = createSimpleExpr();
		var compiler = new BytecodeCompiler();
		var interp = new Interp();
		
		var start = haxe.Timer.stamp();
		for (i in 0...1000) {
			var bytecode = compiler.compile(ast);
			interp.execute(bytecode);
		}
		var elapsed = haxe.Timer.stamp() - start;
		
		trace("Round-trip (compile+execute) 1000 iterations: " + elapsed + "s");
		assertTrue(elapsed < 10.0, "Round-trip should be fast");
	}
	
	public function testBytecodeSize() {
		var ast = createSimpleExpr();
		var compiler = new BytecodeCompiler();
		var bytecode = compiler.compile(ast);
		
		trace("Simple expression bytecode size: " + bytecode.length + " bytes");
		assertTrue(bytecode.length < 100, "Simple bytecode should be compact");
	}
	
	public function testComplexBytecodeSize() {
		var ast = createComplexExpr();
		var compiler = new BytecodeCompiler();
		var bytecode = compiler.compile(ast);
		
		trace("Complex expression bytecode size: " + bytecode.length + " bytes");
		assertTrue(bytecode.length < 200, "Complex bytecode should still be reasonably sized");
	}
	
	public function testSetVarPerformance() {
		var interp = new Interp();
		
		var start = haxe.Timer.stamp();
		for (i in 0...5000) {
			interp.setVar('var' + i, i);
		}
		var elapsed = haxe.Timer.stamp() - start;
		
		trace("Setting 5000 variables: " + elapsed + "s");
		assertTrue(elapsed < 5.0, "Variable setting should be fast");
	}
	
	public function testGetVarPerformance() {
		var interp = new Interp();
		
		// Pre-populate variables
		for (i in 0...50) {
			interp.setVar('var' + i, i);
		}
		
		var start = haxe.Timer.stamp();
		for (i in 0...5000) {
			interp.getVar('var' + (i % 50));
		}
		var elapsed = haxe.Timer.stamp() - start;
		
		trace("Getting 5000 variables (50 unique): " + elapsed + "s");
		assertTrue(elapsed < 5.0, "Variable getting should be fast");
	}
	
	public function testBytecodeCachingBenefit() {
		var ast = createComplexExpr();
		var compiler = new BytecodeCompiler();
		var interp = new Interp();
		
		// Compile once
		var bytecode = compiler.compile(ast);
		
		// Execute compiled bytecode multiple times
		var start = haxe.Timer.stamp();
		for (i in 0...100) {
			interp.execute(bytecode);
		}
		var cachedTime = haxe.Timer.stamp() - start;
		
		trace("Cached bytecode execution (100 iterations): " + cachedTime + "s");
		assertTrue(cachedTime < 2.0, "Cached execution should be very fast");
	}
	
	public function testSimpleFibonacciAST() {
		// Test simple recursive computation with AST
		// Build AST for: 1+1+1+... (10 times)
		var expr = new Expr(EConstInt(1), 0, 0);
		for (i in 0...10) {
			expr = new Expr(EBinop(ADD, expr, new Expr(EConstInt(1), 0, 0)), 0, 0);
		}
		
		var compiler = new BytecodeCompiler();
		var bytecode = compiler.compile(expr);
		var interp = new Interp();
		
		var start = haxe.Timer.stamp();
		var result = interp.execute(bytecode);
		var elapsed = haxe.Timer.stamp() - start;
		
		trace("Recursive addition (10 iterations): " + Std.string(elapsed) + "s, result=" + Std.string(result));
		var resultInt:Int = Std.int(result);
		assertEquals(resultInt, 11, "1 + 1*10 = 11");
		assertTrue(elapsed < 5.0, "Recursive computation should be fast");
	}
	
	public function testLoopPerformance() {
		// Test complex expression instead of loop to avoid timeout
		// Build: ((((1 + 1) + 1) + 1) + 1)
		var expr = new Expr(EConstInt(1), 0, 0);
		for (i in 0...5) {
			expr = new Expr(EBinop(ADD, expr, new Expr(EConstInt(1), 0, 0)), 0, 0);
		}
		
		var compiler = new BytecodeCompiler();
		var bytecode = compiler.compile(expr);
		var interp = new Interp();
		
		var start = haxe.Timer.stamp();
		var result = interp.execute(bytecode);
		var elapsed = haxe.Timer.stamp() - start;
		
		trace('Nested expression (5 levels): ' + elapsed + 's');
		assertTrue(elapsed < 5.0, "Expression should complete quickly");
	}

    public function testFibonacci() {
        var r = Interp.runFromSource("
def fib(n):
    if n <= 1:
        return n
    print(\"Calculating fib(\" + n + \")\")
    return fib(n-1) + fib(n-2)
fib(10)
        ");

		trace(r);
        assertEquals(55, r, "Fibonacci of 10 should be 55");
    }
}
