package paopao.hython;

import haxe.ds.StringMap;

class Dict extends StringMap<Dynamic> {
	public function new() {
		super();
	}

	// Python dict.get(key, default=None)
	public function getWithDefault(key:String, ?defaultValue:Dynamic):Dynamic {
		if (this.exists(key)) {
			return this.get(key);
		}
		return defaultValue;
	}

	// Python dict.keys()
	public function getKeys():Array<String> {
		var result = [];
		for (key in this.keys()) {
			result.push(key);
		}
		return result;
	}

	// Python dict.values()
	public function getValues():Array<Dynamic> {
		var result = [];
		for (key in this.keys()) {
			result.push(this.get(key));
		}
		return result;
	}

	// Python dict.items()
	public function items():Array<Array<Dynamic>> {
		var result = [];
		for (key in this.keys()) {
			result.push([key, this.get(key)]);
		}
		return result;
	}

	// Python dict.update(other)
	public function update(other:Dict):Void {
		for (key in other.keys()) {
			this.set(key, other.get(key));
		}
	}

	// Python dict.pop(key, default=None)
	public function pop(key:String, ?defaultValue:Dynamic):Dynamic {
		if (this.exists(key)) {
			var value = this.get(key);
			this.remove(key);
			return value;
		}
		return defaultValue;
	}

	// Python dict.popitem()
	public function popitem():Array<Dynamic> {
		for (key in this.keys()) {
			var value = this.get(key);
			this.remove(key);
			return [key, value];
		}
		throw "popitem(): dictionary is empty";
	}

	// Python dict.clear()
	public override function clear():Void {
		var keysToRemove = [];
		for (key in this.keys()) {
			keysToRemove.push(key);
		}
		for (key in keysToRemove) {
			this.remove(key);
		}
	}

	// Python dict.copy()
	public override function copy():Dict {
		var newDict = new Dict();
		for (key in this.keys()) {
			newDict.set(key, this.get(key));
		}
		return newDict;
	}

	// Python dict.setdefault(key, default=None)
	public function setdefault(key:String, ?defaultValue:Dynamic):Dynamic {
		if (!this.exists(key)) {
			this.set(key, defaultValue);
			return defaultValue;
		}
		return this.get(key);
	}

	// Python dict.fromkeys(keys, value=None)
	public static function fromKeys(keys:Array<String>, ?value:Dynamic):Dict {
		var d = new Dict();
		for (key in keys) {
			d.set(key, value);
		}
		return d;
	}

	// Python len(dict) - making it a property for easier access
	public var length(get, never):Int;

	private function get_length():Int {
		var count = 0;
		for (_ in this.keys()) {
			count++;
		}
		return count;
	}

	// Python 'in' operator support
	public function contains(key:String):Bool {
		return this.exists(key);
	}

	// Iterator support for Haxe
	public inline override function iterator():Iterator<String> {
		return this.keys();
	}

	// Type-safe getter methods
	public function getInt(key:String, ?defaultValue:Int = 0):Int {
		var value = this.get(key);
		return value != null ? value : defaultValue;
	}

	public function getString(key:String, ?defaultValue:String = ""):String {
		var value = this.get(key);
		return value != null ? value : defaultValue;
	}

	public function getBool(key:String, ?defaultValue:Bool = false):Bool {
		var value = this.get(key);
		return value != null ? value : defaultValue;
	}

	public function getFloat(key:String, ?defaultValue:Float = 0.0):Float {
		var value = this.get(key);
		return value != null ? value : defaultValue;
	}

	public function getArray(key:String, ?defaultValue:Array<Dynamic> = null):Array<Dynamic> {
		var value = this.get(key);
		return value != null ? value : (defaultValue != null ? defaultValue : []);
	}

	public function getDict(key:String, ?defaultValue:Dict = null):Dict {
		var value = this.get(key);
		return value != null ? value : (defaultValue != null ? defaultValue : new Dict());
	}

	// String representation with proper escaping
	public override function toString():String {
		var parts = [];
		for (key in this.keys()) {
			var value = this.get(key);
			var valueStr = formatValue(value);
			var keyStr = escapeString(key);
			parts.push('"' + keyStr + '": ' + valueStr);
		}
		return "{" + parts.join(", ") + "}";
	}

	// Helper method to format values for toString
	private function formatValue(value:Dynamic):String {
		if (value == null) {
			return "null";
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

		if (Std.isOfType(value, Dict)) {
			return value.toString();
		}

		if (Std.isOfType(value, Tuple)) {
			return value.toString();
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

	// Check if two tuples are equal (Python-style)
	public function __eq__(other:Dynamic):Bool {
		if (!Std.isOfType(other, Tuple))
			return false;
		return equals(cast other);
	}

	// Check if two tuples are not equal (Python-style)
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
}

/**
 * Turtle class stub for graphics support
 * This is a placeholder for optional turtle graphics functionality
 */
class Turtle {
	public function new() {
		// Placeholder for turtle graphics
	}
}
