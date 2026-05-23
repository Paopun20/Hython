package tests.tests;

import paopao.hython.Interpreter;
import paopao.hython.Error;
import paopao.hython.PyData.PyValue;
import haxe.ds.StringMap;
import tests.unit.TestCase;

class Test1 extends TestCase {
	public function new() {
		super();
	}

	public function testFunctionCallReturnsArithmetic():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
def add(a, b):
  return a + b
");

		assertPyInt(7, interpreter.callDef("add", [VInt(3), VInt(4)]));
	}

	public function testNestedReturnFromIf():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
def choose(a):
  if a == 1:
    return 10
  return 20
");

		assertPyInt(10, interpreter.callDef("choose", [VInt(1)]));
		assertPyInt(20, interpreter.callDef("choose", [VInt(2)]));
	}

	public function testGlobalFunctionCanReadGlobalAssignment():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
x = 5
def get_x():
  return x
");

		assertPyInt(5, interpreter.callDef("get_x", []));
	}

	public function testSetGlobalAndGetGlobal():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.setGlobal("answer", VInt(42));

		assertPyInt(42, interpreter.getGlobal("answer"));
		assertEquals(null, interpreter.getGlobal("missing"));
	}

	public function testSetGlobalAcceptsHaxeFunction():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.setGlobal("double", function(value:Int):Int {
			return value * 2;
		});

		interpreter.run("result = double(21)\n");

		assertPyInt(42, interpreter.getGlobal("result"));
	}

	public function testTopLevelReturnFails():Void {
		var interpreter = new Interpreter("<test>");

		try {
			interpreter.run("return 1\n");
			fail("top-level return should fail");
		} catch (error:Error) {
			assertEquals("SyntaxError", error.errorName());
		}
	}

	public function testPosInfosTracksCurrentStatement():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("x = 1\ny = 2\n");
		var info = interpreter.posInfos();

		assertTrue(interpreter.curStmt != null);
		assertEquals(2, info.line);
		assertEquals(2, info.lineNumber);
		assertEquals(1, info.col);
		assertEquals(1, info.con);
	}

	public function testHaxeToPyValueConvertsCollections():Void {
		var source = new StringMap<Dynamic>();
		source.set("name", "hython");
		source.set("items", [1, true, null]);

		switch (Interpreter.haxeToPyValue(source)) {
			case VDict(map):
				assertPyString("hython", map.get("name"));
				switch (map.get("items")) {
					case VList(items):
						assertPyInt(1, items[0]);
						assertPyBool(true, items[1]);
						assertEquals(VNone.getName(), items[2].getName());
					default:
						fail("expected list in dict");
				}
			default:
				fail("expected dict");
		}
	}

	public function testPyValueToHaxeConvertsCollections():Void {
		var map = new StringMap<PyValue>();
		map.set("answer", VInt(42));
		map.set("words", VList([VString("hello"), VString("world")]));

		var result:StringMap<Dynamic> = cast Interpreter.pyValueToHaxe(VDict(map));

		assertEquals(42, result.get("answer"));
		var words:Array<Dynamic> = cast result.get("words");
		assertEquals("hello", words[0]);
		assertEquals("world", words[1]);
	}

	public function testHaxeFunctionRoundTripsAsNativeFunction():Void {
		var value = Interpreter.haxeToPyValue(function(a:Int, b:Int):Int {
			return a + b;
		});

		var callable:Dynamic = Interpreter.pyValueToHaxe(value);

		assertEquals(9, callable(4, 5));
	}

	private function assertPyInt(expected:Int, actual:PyValue):Void {
		switch (actual) {
			case VInt(value):
				assertEquals(expected, value);
			default:
				fail("expected VInt(" + expected + ") but got " + Std.string(actual));
		}
	}

	private function assertPyString(expected:String, actual:PyValue):Void {
		switch (actual) {
			case VString(value):
				assertEquals(expected, value);
			default:
				fail("expected VString(" + expected + ") but got " + Std.string(actual));
		}
	}

	private function assertPyBool(expected:Bool, actual:PyValue):Void {
		switch (actual) {
			case VBool(value):
				assertEquals(expected, value);
			default:
				fail("expected VBool(" + expected + ") but got " + Std.string(actual));
		}
	}
}
