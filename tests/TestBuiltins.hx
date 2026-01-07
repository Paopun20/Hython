import tests.unit.TestCase;
import paopao.hython.Parser;
import paopao.hython.Interp;
import haxe.ds.StringMap;

class TestBuiltins extends TestCase {
	function run(code:String):Dynamic {
		var p = new Parser();
		var expr = p.parseString(code);
		return new Interp().execute(expr);
	}

	public function testInt():Void {
		var result = run('int("42")');
		assertEquals(42, result);
	}

	public function testFloat():Void {
		var result = run('float("3.14")');
		assertEquals(3.14, result);
	}

	public function testString():Void {
		var result = run('str(42)');
		assertEquals('42', result);
	}

	public function testBool():Void {
		var result = run('bool(0)');
		assertEquals(false, result);
	}

	public function testList():Void {
		var result = run('list([1, 2, 3])');
		assertEquals([1, 2, 3], result);
	}

	public function testDict():Void {
		var result:StringMap<Dynamic> = run('dict({"a": 1, "b": 2})');
		var obj = result.get("__rootkey__");

		assertEquals(1, obj.a);
		assertEquals(2, obj.b);
	}

	public function testNone():Void {
		var result = run('None');
		assertEquals(null, result);
	}

	public function testNoneType():Void {
		var result = run('type(None)');
		assertEquals('NoneType', result);
	}
}
