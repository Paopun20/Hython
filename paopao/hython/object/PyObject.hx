package paopao.hython.object;

function unsupported(msg:String):String {
	throw "unsupported operation: " + msg;
}

class PyObject {
	public function new() {}

	public function __int__():Int {
		return unsupported("int()");
	}

	public function __str__():String {
		return unsupported("str()");
	}

	public function __repr__():String {
		return unsupported("repr()");
	}

	public function __bool__():Bool {
		return unsupported("bool()");
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
