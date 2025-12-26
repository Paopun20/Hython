package paopao.hython.object;

import paopao.hython.object.PyObject;

class PyInt extends PyObject {
	public var value:Int;

	public function new(v:Int) {
		super();
		value = v;
	}

	override public function pyInt():Int {
		return value;
	}

	override public function pyBool():Bool {
		return value != 0;
	}

	override public function pyRepr():String {
		return Std.string(value);
	}

	override public function pyEq(other:PyObject):Bool {
		return (other is PyInt) && value == cast(other, PyInt).value;
	}

	override public function pyHash():Int {
		return value;
	}
}
