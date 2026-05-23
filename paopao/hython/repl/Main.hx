package paopao.hython.repl;

import haxe.Exception;
import haxe.ds.Vector;
import paopao.hython.Error;
import paopao.hython.Interpreter;
import paopao.hython.PyData.PyValue;
import prismcli.CLI;

class Main {
	static final VERSION = "0.0.4-beta";

	public static function main():Void {
		var cli = new CLI("hython", "Python-like interpreter written in Haxe", VERSION);
		cli.addDefaults();

		var repl = cli.addCommand("repl", "Start an interactive Hython prompt", function(cli, args, flags) {
			startRepl(cli);
		});
		cli.setDefaultCommand(repl);

		var run = cli.addCommand("run", "Run a Hython source file", function(cli, args, flags) {
			var path:String = args["file"];
			var source = sys.io.File.getContent(path);
			runSource(cli, source, path, flags.exists("skip-check"));
		});
		run.addArgument("file", "Path to a Hython source file", String);
		run.addFlag("skip-check", "Skip semantic checking", ["--skip-check"], None);

		var eval = cli.addCommand("eval", "Run inline Hython source", function(cli, args, flags) {
			var source:String = args["source"];
			runSource(cli, source, "<eval>", flags.exists("skip-check"));
		});
		eval.addArgument("source", "Source code to run", String);
		eval.addFlag("skip-check", "Skip semantic checking", ["--skip-check"], None);

		dispatch(cli, Sys.args());
	}

	static function dispatch(cli:CLI, args:Array<String>):Void {
		if (args.length == 0) {
			startRepl(cli);
			return;
		}

		var command = args.shift();
		switch (command) {
			case "--help" | "-h" | "help":
				cli.print(cli.help());
			case "--version" | "-v" | "version":
				cli.print('hython v$VERSION');
			case "repl":
				startRepl(cli);
			case "run":
				runCommand(cli, args);
			case "eval":
				evalCommand(cli, args);
			default:
				cli.print('Unknown command: $command');
				cli.print(cli.help());
				Sys.exit(1);
		}
	}

	static function runCommand(cli:CLI, args:Array<String>):Void {
		var filtered = withoutFlags(args);
		if (filtered.length == 0) {
			cli.print("Missing file argument");
			Sys.exit(1);
		}

		var path = filtered[0];
		runSource(cli, sys.io.File.getContent(path), path, hasFlag(args, "--skip-check"));
	}

	static function evalCommand(cli:CLI, args:Array<String>):Void {
		var filtered = withoutFlags(args);
		if (filtered.length == 0) {
			cli.print("Missing source argument");
			Sys.exit(1);
		}

		runSource(cli, filtered.join(" "), "<eval>", hasFlag(args, "--skip-check"));
	}

	static function hasFlag(args:Array<String>, name:String):Bool {
		return args.indexOf(name) != -1;
	}

	static function withoutFlags(args:Array<String>):Array<String> {
		return [for (arg in args) if (!StringTools.startsWith(arg, "--")) arg];
	}

	static function startRepl(cli:CLI):Void {
		var interpreter = createInterpreter("<repl>");
		cli.print('Hython $VERSION');
		cli.print('Type "exit" or "quit" to leave.');

		while (true) {
			Sys.print(">>> ");
			var line = readLine();

			if (line == null)
				break;

			line = StringTools.trim(line);
			if (line == "")
				continue;
			if (line == "exit" || line == "quit")
				break;

			var source = collectBlock(line);
			try {
				interpreter.run(source);
			} catch (error:Error) {
				cli.print(error.toString());
			} catch (error:Exception) {
				cli.print(error.message);
			} catch (error:Dynamic) {
				cli.print(Std.string(error));
			}
		}
	}

	static function collectBlock(firstLine:String):String {
		if (!StringTools.endsWith(firstLine, ":"))
			return firstLine + "\n";

		var lines = [firstLine];
		while (true) {
			Sys.print("... ");
			var line = readLine();
			if (line == null || StringTools.trim(line) == "")
				break;
			lines.push(line);
		}
		return lines.join("\n") + "\n";
	}

	static function runSource(cli:CLI, source:String, filename:String, skipCheck:Bool):Void {
		try {
			createInterpreter(filename).run(source, skipCheck);
		} catch (error:Error) {
			cli.print(error.toString());
			Sys.exit(1);
		} catch (error:Exception) {
			cli.print(error.message);
			Sys.exit(1);
		} catch (error:Dynamic) {
			cli.print(Std.string(error));
			Sys.exit(1);
		}
	}

	static function createInterpreter(filename:String):Interpreter {
		var interpreter = new Interpreter(filename);
		interpreter.setGlobal("print", VFunction(FNative("print", new Vector<String>(0), function(args:Vector<PyValue>):PyValue {
			Sys.println([for (arg in args) valueToString(arg)].join(" "));
			return VNone;
		})));
		return interpreter;
	}

	static function valueToString(value:PyValue):String {
		return switch (value) {
			case VNone:
				"None";
			case VBool(v):
				v ? "True" : "False";
			case VInt(v):
				Std.string(v);
			case VFloat(v):
				Std.string(v);
			case VString(v):
				Std.string(v);
			default:
				Std.string(value);
		}
	}

	static function readLine():Null<String> {
		try {
			return Sys.stdin().readLine();
		} catch (_:Dynamic) {
			return null;
		}
	}
}
