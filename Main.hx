import sys.io.File;
import Sys;
import paopao.hython.Interp;
import paopao.hython.Parser;
import paopao.hython.bytecode.BytecodeCompiler;
import paopao.hython.bytecode.BytecodeDeserializer;
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
			Sys.stderr().writeString("Usage: hython <file.hython|file.hyb> [--lib name class]\n");
			Sys.exit(1);
			return;
		}

		var content:String;
		try {
			content = File.getContent(file);
		} catch (e:Dynamic) {
			Sys.stderr().writeString("Cannot read file: " + file + "\n");
			Sys.exit(1);
			return;
		}

		var interp = new Interp();
		for (lib in libs) {
			interp.setVar(lib.name, lib.cls);
		}

		try {
			var result:Dynamic;
			
			// Check file extension to determine if it's source or bytecode
			var ext = Path.extension(file);
			if (ext == "hyb") {
				var bytes = File.getBytes(file);
				var deserializer = (new BytecodeDeserializer()).deserialize(bytes);
				result = interp.execute(bytes);
			} else {
				var parser = new Parser(content);
				var ast = parser.parse();
				var compiler = new BytecodeCompiler();
				var bytecode = compiler.compile(ast);
				result = interp.execute(bytecode);
			}
			
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
