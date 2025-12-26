package paopao.hython.runtime;

import paopao.hython.object.PyObject;

class PyDict extends PyObject {
	var buckets:Map<Int, Array<DictEntry>>;

	public function new() {
		super();
		buckets = new Map();
	}

	inline function findEntry(bucket:Array<DictEntry>, key:PyObject):DictEntry {
		for (entry in bucket) {
			if (entry.key.pyEq(key))
				return entry;
		}
		return null;
	}

	public function set(key:PyObject, value:PyObject):Void {
		var h = key.pyHash();
		var bucket = buckets.get(h);

		if (bucket == null) {
			buckets.set(h, [new DictEntry(key, value)]);
			return;
		}

		var entry = findEntry(bucket, key);
		if (entry != null) {
			entry.value = value;
		} else {
			bucket.push(new DictEntry(key, value));
		}
	}

	public function get(key:PyObject):PyObject {
		var h = key.pyHash();
		var bucket = buckets.get(h);

		if (bucket == null)
			throw new PyTypeError("KeyError: " + key.pyRepr());

		var entry = findEntry(bucket, key);
		if (entry == null)
			throw new PyTypeError("KeyError: " + key.pyRepr());

		return entry.value;
	}

	public function contains(key:PyObject):Bool {
		var h = key.pyHash();
		var bucket = buckets.get(h);
		if (bucket == null)
			return false;
		return findEntry(bucket, key) != null;
	}

	override public function pyBool():Bool {
		return !buckets.isEmpty();
	}

	override public function pyEq(other:PyObject):Bool {
		if (!(other is PyDict))
			return false;

		var o = cast(other, PyDict);
		if (this.size() != o.size())
			return false;

		for (bucket in buckets) {
			for (entry in bucket) {
				if (!o.contains(entry.key))
					return false;
				if (!entry.value.pyEq(o.get(entry.key)))
					return false;
			}
		}
		return true;
	}

	override public function pyRepr():String {
		var parts:Array<String> = [];

		for (bucket in buckets) {
			for (entry in bucket) {
				parts.push(entry.key.pyRepr() + ": " + entry.value.pyRepr());
			}
		}

		return "{" + parts.join(", ") + "}";
	}

	override public function pyHash():Int {
		return unsupported("hash()");
	}

	public function size():Int {
		var n = 0;
		for (bucket in buckets)
			n += bucket.length;
		return n;
	}
}
