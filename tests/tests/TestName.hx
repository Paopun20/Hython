package tests.tests;

import tests.unit.TestCase;
import paopao.hython.Ast;
import paopao.hython.Interp;
import paopao.hython.bytecode.BytecodeCompiler;
import paopao.hython.bytecode.BytecodeDeserializer;

class TestName extends TestCase {
	
	public function testBytecodeCompileSimpleInt() {
		var compiler = new BytecodeCompiler();
		var ast = new Expr(EConstInt(42), 0, 0);
		var bytecode = compiler.compile(ast);
		assertTrue(bytecode != null, "Bytecode should not be null");
		assertTrue(bytecode.length > 4, "Bytecode should have header + instructions");
		// Check magic header "HYB\0"
		assertTrue(bytecode.get(0) == 0x48, "First byte should be 'H' (0x48)");
		assertTrue(bytecode.get(1) == 0x59, "Second byte should be 'Y' (0x59)");
		assertTrue(bytecode.get(2) == 0x42, "Third byte should be 'B' (0x42)");
		assertTrue(bytecode.get(3) == 0x00, "Fourth byte should be null (0x00)");
	}
	
	public function testBytecodeDeserializeSimpleInt() {
		var compiler = new BytecodeCompiler();
		var originalAst = new Expr(EConstInt(42), 0, 0);
		var bytecode = compiler.compile(originalAst);
		var deserializer = new BytecodeDeserializer();
		var deserializedAst = deserializer.deserialize(bytecode);
		assertTrue(deserializedAst != null, "Deserialized AST should not be null");
	}
	
	public function testBytecodeRoundTripInt() {
		var interp = new Interp();
		var compiler = new BytecodeCompiler();
		var ast = new Expr(EConstInt(100), 0, 0);
		var bytecode = compiler.compile(ast);
		var result = interp.execute(bytecode);
		assertEquals(100, result, "Round-trip execution of int constant should preserve value");
	}
	
	public function testBytecodeRoundTripString() {
		var interp = new Interp();
		var compiler = new BytecodeCompiler();
		var ast = new Expr(EConstString("hello"), 0, 0);
		var bytecode = compiler.compile(ast);
		var result = interp.execute(bytecode);
		assertEquals("hello", result, "Round-trip execution of string constant should preserve value");
	}
	
	public function testBytecodeRoundTripBool() {
		var interp = new Interp();
		var compiler = new BytecodeCompiler();
		var ast = new Expr(EConstBool(true), 0, 0);
		var bytecode = compiler.compile(ast);
		var result = interp.execute(bytecode);
		assertEquals(true, result, "Round-trip execution of bool constant should preserve value");
	}
	
	public function testBytecodeRoundTripFloat() {
		var interp = new Interp();
		var compiler = new BytecodeCompiler();
		var ast = new Expr(EConstFloat(3.14), 0, 0);
		var bytecode = compiler.compile(ast);
		var result = interp.execute(bytecode);
		var resultFloat:Float = cast result;
		assertTrue(Math.abs(resultFloat - 3.14) < 0.01, "Round-trip execution of float should preserve value");
	}
	
	public function testSetVarGetVar() {
		var interp = new Interp();
		var testObj = {name: "test", value: 42};
		interp.setVar("myObj", testObj);
		var retrieved = interp.getVar("myObj");
		assertTrue(retrieved != null, "Retrieved object should not be null");
		assertEquals(42, retrieved.value, "Retrieved object should have correct value field");
	}
	
	public function testSetVarMultiple() {
		var interp = new Interp();
		interp.setVar("var1", 10);
		interp.setVar("var2", "hello");
		interp.setVar("var3", true);
		
		assertEquals(10, interp.getVar("var1"), "First variable should be preserved");
		assertEquals("hello", interp.getVar("var2"), "Second variable should be preserved");
		assertEquals(true, interp.getVar("var3"), "Third variable should be preserved");
	}
	
	public function testSetVarOverwrite() {
		var interp = new Interp();
		interp.setVar("x", 100);
		assertEquals(100, interp.getVar("x"), "Initial value should be 100");
		interp.setVar("x", 200);
		assertEquals(200, interp.getVar("x"), "Overwritten value should be 200");
	}
	
	public function testBytecodeExecuteBytes() {
		var interp = new Interp();
		var compiler = new BytecodeCompiler();
		var ast = new Expr(EConstInt(99), 0, 0);
		var bytecode = compiler.compile(ast);
		var result = interp.execute(bytecode);
		assertEquals(99, result, "Bytes execution should work correctly");
	}
	
	public function testSetHaxeFunction() {
		var interp = new Interp();
		var haxeFunc = function(x:Int):Int { return x * 2; };
		interp.setVar("doubleFunc", haxeFunc);
		var retrieved = interp.getVar("doubleFunc");
		assertTrue(retrieved != null, "Retrieved function should not be null");
		assertTrue(Reflect.isFunction(retrieved), "Retrieved value should be a function");
	}
	
	public function testCallHaxeFunctionViaReflect() {
		var interp = new Interp();
		var haxeFunc = function(x:Int):Int { return x * 2; };
		interp.setVar("doubleFunc", haxeFunc);
		var retrieved:Dynamic = interp.getVar("doubleFunc");
		var result = Reflect.callMethod(null, retrieved, [5]);
		assertEquals(10, result, "Haxe function should correctly double the input");
	}
	
	public function testSetMultipleFunctions() {
		var interp = new Interp();
		var addFunc = function(a:Int, b:Int):Int { return a + b; };
		var subFunc = function(a:Int, b:Int):Int { return a - b; };
		var mulFunc = function(a:Int, b:Int):Int { return a * b; };
		
		interp.setVar("add", addFunc);
		interp.setVar("sub", subFunc);
		interp.setVar("mul", mulFunc);
		
		var add:Dynamic = interp.getVar("add");
		var sub:Dynamic = interp.getVar("sub");
		var mul:Dynamic = interp.getVar("mul");
		
		assertEquals(7, Reflect.callMethod(null, add, [3, 4]), "Addition should work");
		assertEquals(1, Reflect.callMethod(null, sub, [3, 2]), "Subtraction should work");
		assertEquals(12, Reflect.callMethod(null, mul, [3, 4]), "Multiplication should work");
	}
	
	public function testHaxeFunctionReturnsString() {
		var interp = new Interp();
		var stringFunc = function(prefix:String):String { return prefix + "_result"; };
		interp.setVar("makeString", stringFunc);
		var retrieved:Dynamic = interp.getVar("makeString");
		var result = Reflect.callMethod(null, retrieved, ["test"]);
		assertEquals("test_result", result, "Haxe function should return correct string");
	}
	
	public function testHaxeFunctionNoArgs() {
		var interp = new Interp();
		var noArgFunc = function():Int { return 42; };
		interp.setVar("getAnswer", noArgFunc);
		var retrieved:Dynamic = interp.getVar("getAnswer");
		var result = Reflect.callMethod(null, retrieved, []);
		assertEquals(42, result, "No-arg function should return correct value");
	}
	
	public function testHaxeObjectWithMethod() {
		var interp = new Interp();
		var obj = {
			value: 10,
			increment: function():Int { 
				return 11;
			}
		};
		interp.setVar("counter", obj);
		var retrieved:Dynamic = interp.getVar("counter");
		assertEquals(10, retrieved.value, "Object should have correct initial value");
		var result = Reflect.callMethod(retrieved, retrieved.increment, []);
		assertEquals(11, result, "Object method should return correct value");
	}
}