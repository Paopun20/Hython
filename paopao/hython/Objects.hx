package paopao.hython;

import haxe.ds.StringMap;

class Dict {
	private var elements:StringMap<Dynamic>;

	public function new() {
		elements = new StringMap();
	}

	public inline function set(key:String, value:Dynamic):Void {
		elements.set(key, value);
	}

	public inline function get(key:String):Dynamic {
		return elements.get(key);
	}

	public inline function exists(key:String):Bool {
		return elements.exists(key);
	}

	public inline function remove(key:String):Bool {
		return elements.remove(key);
	}

	public inline function keys():Iterator<String> {
		return elements.keys();
	}

	public function getWithDefault(key:String, ?defaultValue:Dynamic):Dynamic {
		return exists(key) ? get(key) : defaultValue;
	}

	public function getKeys():Array<String> {
		var result = [];
		for (k in keys()) result.push(k);
		return result;
	}

	public function getValues():Array<Dynamic> {
		var result = [];
		for (k in keys()) result.push(get(k));
		return result;
	}

	public function items():Array<Array<Dynamic>> {
		var result = [];
		for (k in keys()) result.push([k, get(k)]);
		return result;
	}

	public function update(other:Dict):Void {
		for (k in other.keys()) {
			set(k, other.get(k));
		}
	}

	public function pop(key:String, ?defaultValue:Dynamic):Dynamic {
		if (exists(key)) {
			var v = get(key);
			remove(key);
			return v;
		}
		return defaultValue;
	}

	public function popitem():Array<Dynamic> {
		for (k in keys()) {
			var v = get(k);
			remove(k);
			return [k, v];
		}
		throw "popitem(): dictionary is empty";
	}

	public function clear():Void {
		var ks = [];
		for (k in keys()) ks.push(k);
		for (k in ks) remove(k);
	}

	public function copy():Dict {
		var d = new Dict();
		for (k in keys()) d.set(k, get(k));
		return d;
	}

	public function setdefault(key:String, ?defaultValue:Dynamic):Dynamic {
		if (!exists(key)) {
			set(key, defaultValue);
			return defaultValue;
		}
		return get(key);
	}

	public static function fromKeys(keys:Array<String>, ?value:Dynamic):Dict {
		var d = new Dict();
		for (k in keys) d.set(k, value);
		return d;
	}

	public var length(get, never):Int;
	private function get_length():Int {
		var n = 0;
		for (_ in keys()) n++;
		return n;
	}

	public inline function contains(key:String):Bool {
		return exists(key);
	}

	public inline function iterator():Iterator<String> {
		return keys();
	}

	public function getInt(key:String, ?defaultValue:Int = 0):Int {
		var v = get(key);
		return v != null ? v : defaultValue;
	}

	public function getString(key:String, ?defaultValue:String = ""):String {
		var v = get(key);
		return v != null ? v : defaultValue;
	}

	public function getBool(key:String, ?defaultValue:Bool = false):Bool {
		var v = get(key);
		return v != null ? v : defaultValue;
	}

	public function getFloat(key:String, ?defaultValue:Float = 0.0):Float {
		var v = get(key);
		return v != null ? v : defaultValue;
	}

	public function getArray(key:String, ?defaultValue:Array<Dynamic>):Array<Dynamic> {
		var v = get(key);
		return v != null ? v : (defaultValue != null ? defaultValue : []);
	}

	public function getDict(key:String, ?defaultValue:Dict):Dict {
		var v = get(key);
		return v != null ? v : (defaultValue != null ? defaultValue : new Dict());
	}

	// Python __getitem__
	public function __getitem__(key:String):Dynamic {
		if (!exists(key)) {
			throw 'KeyError: "$key"';
		}
		return get(key);
	}

	// Python __setitem__
	public function __setitem__(key:String, value:Dynamic):Void {
		set(key, value);
	}

	// Python __delitem__
	public function __delitem__(key:String):Void {
		if (!exists(key)) {
			throw 'KeyError: "$key"';
		}
		remove(key);
	}

	// Python __contains__
	public function __contains__(key:String):Bool {
		return exists(key);
	}

	// Python __len__
	public function __len__():Int {
		return length;
	}

	// Python __eq__
	public function __eq__(other:Dynamic):Bool {
		if (!Std.isOfType(other, Dict)) return false;
		var otherDict:Dict = cast other;
		if (this.length != otherDict.length) return false;
		for (k in keys()) {
			if (!otherDict.exists(k) || get(k) != otherDict.get(k)) {
				return false;
			}
		}
		return true;
	}

	// Python __ne__
	public function __ne__(other:Dynamic):Bool {
		return !__eq__(other);
	}

	public function toString():String {
		var parts = [];
		for (k in keys()) {
			parts.push('"' + escapeString(k) + '": ' + formatValue(get(k)));
		}
		return "{" + parts.join(", ") + "}";
	}

	private function formatValue(value:Dynamic):String {
		if (value == null) return "null";
		if (Std.isOfType(value, String))
			return '"' + escapeString(Std.string(value)) + '"';
		if (Std.isOfType(value, Array)) {
			var arr:Array<Dynamic> = value;
			var out = [];
			for (i in arr) out.push(formatValue(i));
			return "[" + out.join(", ") + "]";
		}
		if (Std.isOfType(value, Dict) || Std.isOfType(value, Tuple))
			return value.toString();
		return Std.string(value);
	}

	private function escapeString(str:String):String {
		str = StringTools.replace(str, "\\", "\\\\");
		str = StringTools.replace(str, '"', '\\"');
		str = StringTools.replace(str, "\n", "\\n");
		str = StringTools.replace(str, "\r", "\\r");
		str = StringTools.replace(str, "\t", "\\t");
		return str;
	}
}

class Tuple {
	private var elements:Array<Dynamic>;

	public function new(?args:Array<Dynamic>) {
		this.elements = args != null ? args.copy() : [];
	}

	// Get element by index (like Python tuple[i])
	public function get(index:Int):Dynamic {
		if (index < 0) {
			// Support negative indexing like Python
			index = this.elements.length + index;
		}
		if (index < 0 || index >= this.elements.length) {
			throw "tuple index out of range";
		}
		return this.elements[index];
	}

	// Check if tuple has an element at index without throwing
	public function hasIndex(index:Int):Bool {
		var idx = index;
		if (idx < 0) {
			idx = this.elements.length + idx;
		}
		return idx >= 0 && idx < this.elements.length;
	}

	// Python len(tuple)
	public var length(get, never):Int;

	private function get_length():Int {
		return this.elements.length;
	}

	// Python tuple.count(value)
	public function count(value:Dynamic):Int {
		var cnt = 0;
		for (elem in this.elements) {
			if (elem == value)
				cnt++;
		}
		return cnt;
	}

	// Python tuple.index(value, start=0, end=length)
	public function indexOf(value:Dynamic, ?start:Int = 0, ?end:Int = -1):Int {
		if (end == -1)
			end = this.elements.length;

		for (i in start...end) {
			if (i >= 0 && i < this.elements.length && this.elements[i] == value) {
				return i;
			}
		}
		throw 'ValueError: tuple.index(x): x not in tuple';
	}

	// Python 'in' operator support
	public function contains(value:Dynamic):Bool {
		for (elem in this.elements) {
			if (elem == value)
				return true;
		}
		return false;
	}

	// Concatenation (like tuple1 + tuple2)
	public function concat(other:Tuple):Tuple {
		var newElements = this.elements.copy();
		for (elem in other.elements) {
			newElements.push(elem);
		}
		return new Tuple(newElements);
	}

	// Repetition (like tuple * n)
	public function repeat(times:Int):Tuple {
		if (times < 0)
			times = 0;
		var newElements = [];
		for (i in 0...times) {
			for (elem in this.elements) {
				newElements.push(elem);
			}
		}
		return new Tuple(newElements);
	}

	// Slice support (like tuple[start:end:step])
	public function slice(?start:Int = 0, ?end:Int = -1, ?step:Int = 1):Tuple {
		if (step == 0) {
			throw "ValueError: slice step cannot be zero";
		}

		var actualEnd = (end == -1) ? this.elements.length : end;
		var actualStart = start;

		if (actualStart < 0)
			actualStart = this.elements.length + actualStart;
		if (actualEnd < 0)
			actualEnd = this.elements.length + actualEnd;

		// Clamp to valid range
		if (actualStart < 0)
			actualStart = 0;
		if (actualEnd > this.elements.length)
			actualEnd = this.elements.length;

		var newElements = [];
		if (step > 0) {
			var i = actualStart;
			while (i < actualEnd) {
				if (i >= 0 && i < this.elements.length) {
					newElements.push(this.elements[i]);
				}
				i += step;
			}
		} else {
			var i = actualStart;
			while (i > actualEnd) {
				if (i >= 0 && i < this.elements.length) {
					newElements.push(this.elements[i]);
				}
				i += step;
			}
		}
		return new Tuple(newElements);
	}

	// Convert to Array
	public function toArray():Array<Dynamic> {
		return this.elements.copy();
	}

	// Get all elements as raw array (internal use)
	public function getElements():Array<Dynamic> {
		return this.elements.copy();
	}

	// Iterator support
	public function iterator():Iterator<Dynamic> {
		return this.elements.iterator();
	}

	// String representation
	public function toString():String {
		var parts = [];
		for (elem in this.elements) {
			parts.push(formatValue(elem));
		}

		// Python uses (x,) for single element tuples
		if (this.elements.length == 1) {
			return "(" + parts[0] + ",)";
		}
		return "(" + parts.join(", ") + ")";
	}

	// Helper method to format values
	private function formatValue(value:Dynamic):String {
		if (value == null) {
			return "None";
		}

		if (Std.isOfType(value, String)) {
			return '"' + escapeString(Std.string(value)) + '"';
		}

		if (Std.isOfType(value, Array)) {
			var arr:Array<Dynamic> = value;
			var items = [];
			for (item in arr) {
				items.push(formatValue(item));
			}
			return "[" + items.join(", ") + "]";
		}

		if (Std.isOfType(value, Tuple)) {
			return value.toString();
		}

		if (Std.isOfType(value, Dict)) {
			return value.toString();
		}

		if (Std.isOfType(value, Bool)) {
			return value ? "True" : "False";
		}

		return Std.string(value);
	}

	// Helper method to escape strings
	private function escapeString(str:String):String {
		str = StringTools.replace(str, "\\", "\\\\");
		str = StringTools.replace(str, '"', '\\"');
		str = StringTools.replace(str, "\n", "\\n");
		str = StringTools.replace(str, "\r", "\\r");
		str = StringTools.replace(str, "\t", "\\t");
		return str;
	}

	// Comparison support
	public function equals(other:Tuple):Bool {
		if (this.length != other.length)
			return false;

		for (i in 0...this.length) {
			if (this.elements[i] != other.elements[i]) {
				return false;
			}
		}
		return true;
	}

	// Hash code for use in maps (simplified)
	public function hashCode():Int {
		var hash = 0;
		for (elem in this.elements) {
			hash = hash * 31 + Std.string(elem).length;
		}
		return hash;
	}

	// Static factory method for easier creation
	public static function of(...args:Dynamic):Tuple {
		return new Tuple([for (arg in args) arg]);
	}

	// Python __getitem__
	public function __getitem__(index:Int):Dynamic {
		return get(index);
	}

	// Python __len__
	public function __len__():Int {
		return length;
	}

	// Python __contains__
	public function __contains__(value:Dynamic):Bool {
		return contains(value);
	}

	// Check if two tuples are equal (Python)
	public function __eq__(other:Dynamic):Bool {
		if (!Std.isOfType(other, Tuple))
			return false;
		return equals(cast other);
	}

	// Check if two tuples are not equal (Python)
	public function __ne__(other:Dynamic):Bool {
		return !__eq__(other);
	}

	// Less than comparison
	public function __lt__(other:Dynamic):Bool {
		if (!Std.isOfType(other, Tuple))
			return false;
		var otherTuple:Tuple = cast other;
		var minLen = this.length < otherTuple.length ? this.length : otherTuple.length;
		for (i in 0...minLen) {
			var a = this.elements[i];
			var b = otherTuple.elements[i];
			if (a < b)
				return true;
			if (a > b)
				return false;
		}
		return this.length < otherTuple.length;
	}

	// Greater than comparison
	public function __gt__(other:Dynamic):Bool {
		if (!Std.isOfType(other, Tuple))
			return false;
		var otherTuple:Tuple = cast other;
		return otherTuple.__lt__(this);
	}

	// Less than or equal comparison
	public function __le__(other:Dynamic):Bool {
		return __lt__(other) || __eq__(other);
	}

	// Greater than or equal comparison
	public function __ge__(other:Dynamic):Bool {
		return __gt__(other) || __eq__(other);
	}

	// Python __add__ (concatenation)
	public function __add__(other:Dynamic):Tuple {
		if (!Std.isOfType(other, Tuple))
			throw "TypeError: can only concatenate tuple to tuple";
		return concat(cast other);
	}

	// Python __mul__ (repetition)
	public function __mul__(times:Int):Tuple {
		return repeat(times);
	}
}

class PyArray<T = Dynamic> {
	private var elements:Array<Dynamic>;

	public function new(?args:Array<Dynamic>) {
		this.elements = args != null ? args.copy() : [];
	}

	// Get element by index with Python negative indexing
	public function get(index:Int):Dynamic {
		var idx = index < 0 ? this.elements.length + index : index;
		if (idx < 0 || idx >= this.elements.length) {
			throw "list index out of range";
		}
		return this.elements[idx];
	}

	// Set element by index with Python negative indexing
	public function set(index:Int, value:Dynamic):Void {
		var idx = index < 0 ? this.elements.length + index : index;
		if (idx < 0 || idx >= this.elements.length) {
			throw "list assignment index out of range";
		}
		this.elements[idx] = value;
	}

	// Array access operators
	@:arrayAccess
	public inline function arrayRead(index:Int):Dynamic {
		var idx = index < 0 ? this.elements.length + index : index;
		return this.elements[idx];
	}

	@:arrayAccess
	public inline function arrayWrite(index:Int, value:Dynamic):Dynamic {
		var idx = index < 0 ? this.elements.length + index : index;
		this.elements[idx] = value;
		return value;
	}

	// Python len(list)
	public var length(get, never):Int;

	private inline function get_length():Int {
		return this.elements.length;
	}

	// Python list.append(value)
	public inline function append(value:Dynamic):Void {
		this.elements.push(value);
	}

	// Alias for native push
	public inline function push(value:Dynamic):Void {
		this.elements.push(value);
	}

	// Python list.extend(iterable)
	public function extend(other:Dynamic):Void {
		if (Std.isOfType(other, PyArray)) {
			for (elem in cast(other, PyArray<Dynamic>)) {
				this.elements.push(elem);
			}
		} else if (Std.isOfType(other, Array)) {
			for (elem in cast(other, Array<Dynamic>)) {
				this.elements.push(elem);
			}
		}
	}

	// Python list.insert(index, value)
	public function insert(index:Int, value:Dynamic):Void {
		var idx = index < 0 ? this.elements.length + index : index;
		if (idx < 0) idx = 0;
		if (idx > this.elements.length) idx = this.elements.length;
		this.elements.insert(idx, value);
	}

	// Python list.remove(value) - removes first occurrence
	public function remove(value:Dynamic):Void {
		for (i in 0...this.elements.length) {
			if (this.elements[i] == value) {
				this.elements.splice(i, 1);
				return;
			}
		}
		throw 'ValueError: list.remove(x): x not in list';
	}

	// Python list.pop(index=-1)
	public function pop(?index:Int = -1):Dynamic {
		if (this.elements.length == 0) {
			throw "pop from empty list";
		}
		var idx = index < 0 ? this.elements.length + index : index;
		if (idx < 0 || idx >= this.elements.length) {
			throw "pop index out of range";
		}
		var value = this.elements[idx];
		this.elements.splice(idx, 1);
		return value;
	}

	// Python list.clear()
	public function clear():Void {
		this.elements.splice(0, this.elements.length);
	}

	// Python list.index(value, start=0, end=length) - returns -1 if not found
	public function indexOf(value:Dynamic, ?start:Int = 0, ?end:Int = -1):Int {
		var endIdx = end == -1 ? this.elements.length : end;
		for (i in start...endIdx) {
			if (i >= 0 && i < this.elements.length && this.elements[i] == value) {
				return i;
			}
		}
		return -1;
	}

	// Python index that throws an exception
	public function index(value:Dynamic, ?start:Int = 0, ?end:Int = -1):Int {
		var idx = indexOf(value, start, end);
		if (idx == -1) {
			throw 'ValueError: ${value} is not in list';
		}
		return idx;
	}

	// Python list.count(value)
	public function count(value:Dynamic):Int {
		var cnt = 0;
		for (elem in this.elements) {
			if (elem == value) cnt++;
		}
		return cnt;
	}

	// Python list.sort(key=None, reverse=False)
	private function sortPy(?reverse:Bool = false):Void {
		this.elements.sort(function(a, b) {
			if (a < b) return reverse ? 1 : -1;
			if (a > b) return reverse ? -1 : 1;
			return 0;
		});
	}

	// Override to accept either a comparison function or boolean
	public function sort(?compareFn:Dynamic):Void {
		if (compareFn == null || Std.isOfType(compareFn, Bool)) {
			sortPy(compareFn == true);
		} else if (Reflect.isFunction(compareFn)) {
			this.elements.sort(compareFn);
		} else {
			sortPy(false);
		}
	}

	// Python list.reverse()
	public inline function reverse():Void {
		this.elements.reverse();
	}

	// Python list.copy()
	public function copy():PyArray<T> {
		return new PyArray(this.elements.copy());
	}

	// Python 'in' operator support
	public function contains(value:Dynamic):Bool {
		for (elem in this.elements) {
			if (elem == value) return true;
		}
		return false;
	}

	// Concatenation (like list1 + list2)
	public function concat(other:PyArray<T>):PyArray<T> {
		var newElements = this.elements.copy();
		for (elem in other) {
			newElements.push(elem);
		}
		return new PyArray(newElements);
	}

	// Repetition (like list * n)
	public function repeat(times:Int):PyArray<T> {
		var t = times < 0 ? 0 : times;
		var newElements = [];
		for (i in 0...t) {
			for (elem in this.elements) {
				newElements.push(elem);
			}
		}
		return new PyArray(newElements);
	}

	// Slice support (like list[start:end:step])
	public function slice(?start:Int = 0, ?end:Int = -1, ?step:Int = 1):PyArray<T> {
		if (step == 0) throw "ValueError: slice step cannot be zero";

		var actualEnd = end == -1 ? this.elements.length : (end < 0 ? this.elements.length + end : end);
		var actualStart = start < 0 ? this.elements.length + start : start;

		if (actualStart < 0) actualStart = 0;
		if (actualEnd > this.elements.length) actualEnd = this.elements.length;

		var newElements = [];
		if (step > 0) {
			var i = actualStart;
			while (i < actualEnd) {
				if (i >= 0 && i < this.elements.length) {
					newElements.push(this.elements[i]);
				}
				i += step;
			}
		} else {
			var i = actualStart;
			while (i > actualEnd) {
				if (i >= 0 && i < this.elements.length) {
					newElements.push(this.elements[i]);
				}
				i += step;
			}
		}
		return new PyArray(newElements);
	}

	// Convert to native Haxe Array
	public inline function toArray():Array<Dynamic> {
		return this.elements.copy();
	}

	// Get raw elements
	public inline function getElements():Array<Dynamic> {
		return this.elements.copy();
	}

	// Iterator support
	public inline function iterator():Iterator<Dynamic> {
		return this.elements.iterator();
	}

	// String representation
	public function toString():String {
		var parts = [];
		for (elem in this.elements) {
			parts.push(formatValue(elem));
		}
		return "[" + parts.join(", ") + "]";
	}

	// Helper method to format values
	private function formatValue(value:Dynamic):String {
		if (value == null) return "None";
		if (Std.isOfType(value, String)) return '"' + escapeString(Std.string(value)) + '"';
		if (Std.isOfType(value, PyArray)) {
			var arr = cast(value, PyArray<Dynamic>);
			var items = [];
			for (item in arr.elements) {
				items.push(formatValue(item));
			}
			return "[" + items.join(", ") + "]";
		}
		if (Std.isOfType(value, Array)) {
			var arr:Array<Dynamic> = value;
			var items = [];
			for (item in arr) {
				items.push(formatValue(item));
			}
			return "[" + items.join(", ") + "]";
		}
		if (Std.isOfType(value, Tuple)) return value.toString();
		if (Std.isOfType(value, Dict)) return value.toString();
		if (Std.isOfType(value, Bool)) return value ? "True" : "False";
		return Std.string(value);
	}

	// Helper method to escape strings
	private function escapeString(str:String):String {
		var s = str;
		s = StringTools.replace(s, "\\", "\\\\");
		s = StringTools.replace(s, '"', '\\"');
		s = StringTools.replace(s, "\n", "\\n");
		s = StringTools.replace(s, "\r", "\\r");
		s = StringTools.replace(s, "\t", "\\t");
		return s;
	}

	// Comparison support
	public function equals(other:PyArray<T>):Bool {
		if (this.elements.length != other.elements.length) return false;
		for (i in 0...this.elements.length) {
			if (this.elements[i] != other.elements[i]) return false;
		}
		return true;
	}

	// Static factory method
	public static function of(...args:Dynamic):PyArray<Dynamic> {
		var arr = new PyArray();
		for (arg in args) {
			arr.push(arg);
		}
		return arr;
	}

	// Python comparison methods
	public function __eq__(other:Dynamic):Bool {
		if (!Std.isOfType(other, PyArray)) return false;
		return equals(cast other);
	}

	public function __ne__(other:Dynamic):Bool {
		return !__eq__(other);
	}

	public function __lt__(other:Dynamic):Bool {
		if (!Std.isOfType(other, PyArray)) return false;
		var otherArray = cast(other, PyArray);
		var minLen = this.elements.length < otherArray.elements.length ? this.elements.length : otherArray.elements.length;
		for (i in 0...minLen) {
			var a = this.elements[i];
			var b = otherArray.elements[i];
			if (a < b) return true;
			if (a > b) return false;
		}
		return this.elements.length < otherArray.elements.length;
	}

	public function __gt__(other:Dynamic):Bool {
		if (!Std.isOfType(other, PyArray)) return false;
		var otherArray = cast(other, PyArray);
		var minLen = this.elements.length < otherArray.elements.length ? this.elements.length : otherArray.elements.length;
		for (i in 0...minLen) {
			var a = this.elements[i];
			var b = otherArray.elements[i];
			if (a > b) return true;
			if (a < b) return false;
		}
		return this.elements.length > otherArray.elements.length;
	}

	public function __le__(other:Dynamic):Bool {
		return __lt__(other) || __eq__(other);
	}

	public function __ge__(other:Dynamic):Bool {
		return __gt__(other) || __eq__(other);
	}
}