package paopao.hython.object;

import paopao.hython.object.PyObject;

class PyInt extends PyObject {
	public var value:Int;

	public function new(v:Int) {
		super();
		value = v;
	}

	override public function __int__():Int {
		return value;
	}

	override public function __bool__():Bool {
		return value != 0;
	}

	override public function __repr__():String {
		return Std.string(value);
	}

	override public function __eq__(other:PyObject):Bool {
		return (other is PyInt) && value == cast(other, PyInt).value;
	}

	override public function __hash__():Int {
		return value;
	}
}
