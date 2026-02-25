import tests.unit.TestCase;
import paopao.hython.Parser;
import paopao.hython.Interp;
import haxe.ds.StringMap;

class HaxeClass {
	public function new() {
		this.value = 42;
	}

	public function call():String {
		return 'hello';
	}

	public var value:Int;
}

class TestInjector extends TestCase {
	function run(code:String, injector:StringMap<Dynamic>):Dynamic {
		var p = new Parser();
		var expr = p.parseString(code);
		var runtime = new Interp();
		for (key in injector.keys()) {
			runtime.setVar(key, injector.get(key));
		}
		return runtime.execute(expr);
	}

	function testInjectorVars() {
		var injector = new StringMap<Dynamic>();
		injector.set("x", 10);
		injector.set("y", 20);
		var result = run("x + y", injector);
		assertEquals(30, result);
	}

	function testInjectorFunctions() {
		var injector = new StringMap<Dynamic>();
		injector.set("add", function(a:Int, b:Int):Int {
			return a + b;
		});
		var result = run("add(10, 20)", injector);
		assertEquals(30, result);
	}

	function testInjectorObjects() {
		var injector = new StringMap<Dynamic>();
		injector.set("person", {name: "John", age: 30});
		var result = run("person.name", injector);
		assertEquals("John", result);
	}

	function testInjectorArrays() {
		var injector = new StringMap<Dynamic>();
		injector.set("numbers", [1, 2, 3]);
		var result = run("numbers[1]", injector);
		assertEquals(2, result);
	}

	function testInjectorMixed() {
		var injector = new StringMap<Dynamic>();
		injector.set("add", function(a:Int, b:Int):Int {
			return a + b;
		});
		injector.set("person", {name: "John", age: 30});
		injector.set("numbers", [1, 2, 3]);
		var result = run("add(person.age, numbers[1])", injector);
		assertEquals(32, result);
	}

	function testInjectorReverse() {
		var p = new Parser();
		var expr = p.parseString("def main():\n     return 'hello'");
		var runtime = new Interp();
		runtime.execute(expr);
		assertEquals("hello", runtime.calldef("main", []));
	}

	function testTopLevelDefIsGlobal() {
		var p = new Parser();
		var expr = p.parseString("
def foo():
    return 123
");
		var runtime = new Interp();
		runtime.execute(expr);

		assertTrue(runtime.getdef("foo") == true); // be true it exists
		assertEquals(123, runtime.calldef("foo", []));
	}

	function testMultipleDefs() {
		var p = new Parser();
		var expr = p.parseString("
def a():
    return 1
def b():
    return 2
");
		var runtime = new Interp();
		runtime.execute(expr);

		assertEquals(1, runtime.calldef("a", []));
		assertEquals(2, runtime.calldef("b", []));
	}

	function testHaxeClass() {
		var injector = new StringMap<Dynamic>();
		injector.set("HaxeClass", HaxeClass);
		var result = run("
haxe = HaxeClass()
haxe.value = 42
haxe.call() == 'hello'
		", injector);
		assertEquals(true, result);
	}
}
