package;

import paopao.hython.*;

class TestMain {
	static function main() {
		var source = "def add(x, y):\n  return x + y\n\nresult = add(2, 3)";
		try {
			var result = VM.runFromSource(source);
			trace("Result: " + result);
		} catch (error:Error) {
			var msg = Traceback.simple(source, error);
			trace(msg);
		}
	}
}