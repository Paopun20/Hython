import tests.unit.TestCase;
import paopao.hython.Parser;
import paopao.hython.Interp;
import haxe.ds.StringMap;

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
}
