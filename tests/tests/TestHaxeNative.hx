package tests.tests;

import paopao.hython.Compiler;
import paopao.hython.Lexer;
import paopao.hython.Parser;
import paopao.hython.Semantic;
import paopao.hython.VM;
import paopao.hython.VM.Value;
import tests.unit.TestCase;

class TestNative {
	public var x:Int;

	public function new(x:Int) {
		this.x = x;
	}

	public function add(y:Int):Int {
		return x + y;
	}
}

class TestHaxeNative extends TestCase {
	public function new() {
		super();
	}

	public function testSetNativeFunction():Void {
		var vm = new VM();

		vm.setNativeFunction("add", function(a:Int, b:Int) {
			return a + b;
		});

		executeInto(vm, "
result = add(2, 3)
		");

		var result = vm.getGlobal("result");

		@:privateAccess assertEquals("5", vm.valueToString(result));
	}

	public function testSetNativeClass():Void {
		var vm = new VM();

		vm.setNativeClass("Test", TestNative);

		executeInto(vm, "
t = Test(10)
result = t.add(5)
		");

		var result = vm.getGlobal("result");

		@:privateAccess assertEquals("15", vm.valueToString(result));
	}

	private function executeInto(vm:VM, source:String):Void {
		var lexer = new Lexer(source);
		var tokens = lexer.tokenize();
		var program = new Parser(tokens, lexer.tokenPositions).parse();
		new Semantic().analyze(program, "<test>");
		var code = new Compiler().compile(program);
		vm.execute(code);
	}
}