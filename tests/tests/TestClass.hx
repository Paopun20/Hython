package tests.tests;

import paopao.hython.Interpreter;
import paopao.hython.Error;
import paopao.hython.Library;
import paopao.hython.PyData.PyValue;
import haxe.ds.StringMap;
import tests.unit.TestCase;

class TestClass extends TestCase {
	public function testBasicClassWithClassVariable():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class MyClass:
    i = 12345

x = MyClass()
");

		var instance = interpreter.getGlobal("x");
		switch (instance) {
			case VInstance(cls, fields):
				assertPyInt(12345, fields.get("i"));
			default:
				fail("expected VInstance but got " + Std.string(instance));
		}
	}

	public function testBasicClassWithMethod():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class MyClass:
    def f(self):
        return 'hello world'

x = MyClass()
result = x.f()
");

		assertPyString('hello world', interpreter.getGlobal("result"));
	}

	public function testClassWithInit():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class Complex:
    def __init__(self, realpart, imagpart):
        self.r = realpart
        self.i = imagpart

x = Complex(3.0, 0 - 4.5)
");

		var instance = interpreter.getGlobal("x");
		switch (instance) {
			case VInstance(cls, fields):
				assertPyFloat(3.0, fields.get("r"));
			default:
				fail("expected VInstance but got " + Std.string(instance));
		}
	}

	public function testClassInitInstanceVariable():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class Complex:
    def __init__(self, realpart, imagpart):
        self.r = realpart
        self.i = imagpart

x = Complex(3.0, 0 - 4.5)
");

		var instance = interpreter.getGlobal("x");
		switch (instance) {
			case VInstance(cls, fields):
				assertPyFloat(-4.5, fields.get("i"));
			default:
				fail("expected VInstance but got " + Std.string(instance));
		}
	}

	public function testClassMethodWithSelfAccess():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class MyClass:
    def __init__(self, value):
        self.value = value
    
    def get_value(self):
        return self.value

x = MyClass(42)
result = x.get_value()
");

		assertPyInt(42, interpreter.getGlobal("result"));
	}

	public function testMultipleInstances():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class MyClass:
    def __init__(self, value):
        self.value = value
    
    def get_value(self):
        return self.value

x = MyClass(10)
y = MyClass(20)
result = x.get_value() + y.get_value()
");

		assertPyInt(30, interpreter.getGlobal("result"));
	}

	public function testClassVariableAccess():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class MyClass:
    count = 100
    
    def get_count(self):
        return self.count

x = MyClass()
result = x.get_count()
");

		assertPyInt(100, interpreter.getGlobal("result"));
	}

	public function testClassInheritance():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class Base:
    def greet(self):
        return 'Base'

class Derived(Base):
    pass

x = Derived()
result = x.greet()
");

		assertPyString('Base', interpreter.getGlobal("result"));
	}

	public function testClassInheritanceMethodOverride():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class Base:
    def greet(self):
        return 'Base'

class Derived(Base):
    def greet(self):
        return 'Derived'

x = Derived()
result = x.greet()
");

		assertPyString('Derived', interpreter.getGlobal("result"));
	}

	public function testClassWithDocstring():Void {
		var interpreter = new Interpreter("<test>");

		interpreter.run("
class MyClass:
    \"\"\"A simple example class\"\"\"
    i = 12345

x = MyClass()
");

		var instance = interpreter.getGlobal("x");
		switch (instance) {
			case VInstance(cls, fields):
				assertPyInt(12345, fields.get("i"));
			default:
				fail("expected VInstance but got " + Std.string(instance));
		}
	}

	private function assertPyInt(expected:Int, actual:PyValue):Void {
		switch (actual) {
			case VInt(value):
				assertEquals(expected, value);
			default:
				fail("expected VInt(" + expected + ") but got " + Std.string(actual));
		}
	}

	private function assertPyFloat(expected:Float, actual:PyValue):Void {
		switch (actual) {
			case VFloat(value):
				assertEquals(expected, value);
			default:
				fail("expected VFloat(" + expected + ") but got " + Std.string(actual));
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
}
