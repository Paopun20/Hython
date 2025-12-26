package paopao.hython.object;

import paopao.hython.object.PyObject;

class PyList extends PyObject {
	public var items:Array<PyObject>;

	public function new(items:Array<PyObject>) {
		super();
		this.items = items;
	}

	public function append(value:PyObject):Void {
		items.push(value);
	}

	public function pop(index:Int = -1):PyObject {
		if (index < 0 || index >= items.length)
			throw new PyIndexError("pop index out of range");
		return items.splice(index, 1)[0];
	}

	public function clear():Void {
		items.length = 0;
	}

	public function insert(index:Int, value:PyObject):Void {
		items.splice(index, 0, value);
	}

	override public function pyBool():Bool {
		return items.length != 0;
	}

	override public function pyEq(other:PyObject):Bool {
		if (!(other is PyList))
			return false;

		var o = cast(other, PyList);
		if (items.length != o.items.length)
			return false;

		for (i in 0...items.length) {
			if (!items[i].pyEq(o.items[i]))
				return false;
		}
		return true;
	}

	override public function pyRepr():String {
		var parts:Array<String> = [];
		for (item in items) {
			parts.push(item.pyRepr());
		}
		return "[" + parts.join(", ") + "]";
	}

	override public function pyStr():String {
		return pyRepr();
	}

	override public function pyHash():Int {
		return unsupported("hash()");
	}
}
