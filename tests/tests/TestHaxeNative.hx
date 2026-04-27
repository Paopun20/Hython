package tests.tests;

import paopao.hython.*;
import tests.unit.TestCase;

class TestNative {
	public var x:Int;

	public function new(x:Int) {
		this.x = x;
	}

	public function add(y:Int):Int {
		return x + y;
	}

	public function add2(y:Int, z:Int):Int {
		return x + y + z;
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

		executeInto(vm, "
t = Test(10)
result = t.add2(5, 3)
		");

		var result2 = vm.getGlobal("result");

		@:privateAccess assertEquals("18", vm.valueToString(result2));
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
