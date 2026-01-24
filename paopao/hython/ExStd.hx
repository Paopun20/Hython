package paopao.hython;

@:allow(paopao.hython.Interp)
class ExStd {
	private static function bool(value:Dynamic):Bool {
		if (value == null)
			return false;

		if (value is Bool)
			return value;

		if (value is Int || value is Float)
			return value != 0;

		if (value is String)
			return value.length > 0;

		if (value is Array)
			return value.length > 0;

		if (Type.typeof(value) == TObject) {
			return Reflect.fields(value).length > 0;
		}

		return true;
	}
}
