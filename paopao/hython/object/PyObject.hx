package paopao.hython.object;

class PyObject {
	public function new() {}

	public function pyInt():Int {
		return unsupported("int()");
	}

	public function pyStr():String {
		return unsupported("str()");
	}

	public function pyRepr():String {
		return pyStr();
	}

	public function pyBool():Bool {
		return false;
	}

	public function pyEq(other:PyObject):Bool {
		return this == other;
	}

	public function pyHash():Int {
		return unsupported("hash()");
	}
}
