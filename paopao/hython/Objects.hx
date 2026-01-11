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