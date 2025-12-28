package paopao.hython.object;

class PyObject {
	public function new() {}

	public function __int__():Int {
		return unsupported("int()");
	}

	public function __str__():String {
		return unsupported("str()");
	}

	public function __repr__():String {
		return pyStr();
	}

	public function __bool__():Bool {
		return false;
	}

	public function __eq__(other:PyObject):Bool {
		return this == other;
	}

	public function __lt__(other:PyObject):Bool {
		return this == other;
	}

	public function __hash__():Int {
		return unsupported("hash()");
	}
}
