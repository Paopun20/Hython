import sys.io.File;
import Sys;
import paopao.hython.Interp;
import paopao.hython.Parser;
import paopao.hython.Printer;
import haxe.io.Path;

typedef LibEntry = {
	var name:String;
	var cls:Class<Dynamic>;
}

class Main {
	static function main() {
		var args = Sys.args();

		var file:String = null;
		var libs:Array<LibEntry> = [];

		var i = 0;
		while (i < args.length) {
			switch (args[i]) {
				default:
					if (file == null)
						file = args[i];
					else {
						Sys.stderr().writeString("Unexpected argument: " + args[i] + "\n");
						Sys.exit(1);
					}
					i++;
			}
		}

		if (file == null) {
			Sys.stderr().writeString("Usage: app <file.py> [-lib ClassName]\n");
			Sys.exit(1);
		}

		var content = File.getContent(file);
		try {
			content = File.getContent(file);
		} catch (e:Dynamic) {
			Sys.stderr().writeString("Cannot read file: " + file + "\n");
			Sys.exit(1);
			return;
		}

		var tokens;
		try {
			tokens = (new Parser()).parseString(content);
		} catch (e:Dynamic) {
			Sys.stderr().writeString("Parse error:\n" + e + "\n");
			Sys.exit(2);
			return;
		}

		try {
			var interp = (new Interp());
			for (lib in libs) {
				interp.setVar(lib.name, lib.cls);
			}
			var result = interp.execute(tokens);
			if (result != null)
				Sys.println(result);
		} catch (e:Dynamic) {
			Sys.stderr().writeString("Runtime error:\n" + e + "\n");
			Sys.exit(3);
			return;
		}

		Sys.exit(0);
	}
}
