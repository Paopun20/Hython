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
	public function getItems():Array<Array<Dynamic>> {
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

	// Python len(dict)
	public function length():Int {
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

	
	// Python dict.items()
	public function items():Array<Array<Dynamic>> {
		var result = [];
		for (key in this.keys()) {
			result.push([key, this.get(key)]);
		}
		return result;
	}

	// String representation
	public override function toString():String {
		var parts = [];
		for (key in this.keys()) {
			var value = this.get(key);
			var valueStr = Std.string(value);
			if (Std.isOfType(value, String)) {
				valueStr = '"' + valueStr + '"';
			}
			parts.push('"' + key + '": ' + valueStr);
		}
		return "{" + parts.join(", ") + "}";
	}
}
