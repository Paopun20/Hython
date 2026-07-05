package paopao.hython.repl;
import haxe.Exception;
import haxe.ds.Vector;
import paopao.hython.Error;
import paopao.hython.Interpreter;
import paopao.hython.PyData.PyValue;
import prismcli.CLI;

class Main {
	static final VERSION = "0.1.0-rc.1";

	static final ANSI_RED = "\x1b[31m";
	static final ANSI_GREEN = "\x1b[32m";
	static final ANSI_YELLOW = "\x1b[33m";
	static final ANSI_CYAN = "\x1b[36m";
	static final ANSI_GRAY = "\x1b[90m";
	static final ANSI_RESET = "\x1b[0m";

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
			runSource(cli, source, path);
		});
		run.addArgument("file", "Path to a Hython source file", String);
		run.addFlag("skip-check", "Skip semantic checking", ["--skip-check"], None);

		var eval = cli.addCommand("eval", "Run inline Hython source", function(cli, args, flags) {
			var source:String = args["source"];
			runSource(cli, source, "<eval>");
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
		runSource(cli, sys.io.File.getContent(path), path);
	}

	static function evalCommand(cli:CLI, args:Array<String>):Void {
		var filtered = withoutFlags(args);
		if (filtered.length == 0) {
			cli.print("Missing source argument");
			Sys.exit(1);
		}

		runSource(cli, filtered.join(" "), "<eval>");
	}

	static function hasFlag(args:Array<String>, name:String):Bool {
		return args.indexOf(name) != -1;
	}

	static function withoutFlags(args:Array<String>):Array<String> {
		return [for (arg in args) if (!StringTools.startsWith(arg, "--")) arg];
	}

	static function startRepl(cli:CLI):Void {
		var interpreter = createInterpreter("<repl>");
		var history = new Array<String>();

		cli.print(color(ANSI_CYAN, 'Hython $VERSION (type "help()" for help)'));
		cli.print(color(ANSI_GRAY, "exit() or Ctrl+D to quit"));

		interpreter.onExprResult = function(v:PyValue) {
			switch (v) {
				case VNone:
				case VString(s):
					Sys.println(color(ANSI_YELLOW, "'" + s + "'"));
				default:
					Sys.println(color(ANSI_YELLOW, Interpreter.valueToString(v)));
			}
		};

		while (true) {
			Sys.print(color(ANSI_GREEN, ">>> "));
			var line = readLine();

			if (line == null)
				break;

			line = StringTools.trim(line);
			if (line == "")
				continue;

			if (handleSpecialCommand(line, history, interpreter, cli))
				continue;

			history.push(line);
			var source = collectBlock(line);
			try {
				interpreter.run(source);
			} catch (error:Error) {
				printError(error);
			} catch (error:Exception) {
				Sys.println(color(ANSI_RED, error.message));
			} catch (error:Dynamic) {
				Sys.println(color(ANSI_RED, Std.string(error)));
			}
		}
	}

	static function handleSpecialCommand(line:String, history:Array<String>, interpreter:Interpreter, cli:CLI):Bool {
		switch (line) {
			case "exit" | "quit":
				Sys.exit(0);
				return true;
			case "help()":
				cli.print(color(ANSI_CYAN, "Hython $VERSION - Python-like interpreter in Haxe"));
				cli.print("  exit / quit    — leave the REPL");
				cli.print("  help()         — show this message");
				cli.print("  history        — show command history");
				cli.print("  !N             — replay command N from history");
				cli.print("  license()      — show license info");
				cli.print("  credits()      — show credits");
				return true;
			case "history":
				for (i in 0...history.length) {
					Sys.println(color(ANSI_GRAY, '$i: ${history[i]}'));
				}
				return true;
			case "license()":
				cli.print("Hython is released under the MIT License.");
				return true;
			case "credits()":
				cli.print("Hython written by Paopun20 and contributors.");
				return true;
		}

		if (line.charAt(0) == "!") {
			var num = Std.parseInt(line.substr(1));
			if (num == null || num < 0 || num >= history.length) {
				Sys.println(color(ANSI_RED, "Unknown history index: $line"));
				return true;
			}
			var replay = history[num];
			Sys.println(color(ANSI_GRAY, 'Replaying: $replay'));
			history.push(replay);
			var source = collectBlock(replay);
			try {
				interpreter.run(source);
			} catch (error:Error) {
				printError(error);
			} catch (error:Exception) {
				Sys.println(color(ANSI_RED, error.message));
			} catch (error:Dynamic) {
				Sys.println(color(ANSI_RED, Std.string(error)));
			}
			return true;
		}

		return false;
	}

	static function collectBlock(firstLine:String):String {
		var lines = [firstLine];

		while (needsMoreLines(lines)) {
			Sys.print(color(ANSI_GREEN, "... "));
			var line = readLine();
			if (line == null)
				break;

			var trimmed = StringTools.trim(line);
			if (trimmed == "" && isBalancedLines(lines) && !endsWithColon(lastLine(lines))) {
				break;
			}

			lines.push(line);
		}

		return lines.join("\n") + "\n";
	}

	static function needsMoreLines(lines:Array<String>):Bool {
		if (lines.length == 1) {
			var l = StringTools.trim(lines[0]);
			if (endsWithColon(l))
				return true;
			if (!isBalancedLines(lines))
				return true;
			return false;
		}

		return !isBalancedLines(lines) || endsWithColon(lastLine(lines));
	}

	static function isBalancedLines(lines:Array<String>):Bool {
		var code = lines.join("\n");
		return isBalanced(code);
	}

	static function endsWithColon(line:String):Bool {
		var trimmed = StringTools.trim(line);
		if (trimmed == "")
			return false;
		var noComment = trimComment(trimmed);
		return StringTools.endsWith(noComment, ":");
	}

	static function trimComment(line:String):String {
		var idx = line.indexOf("#");
		return idx == -1 ? line : line.substr(0, idx);
	}

	static function lastLine(lines:Array<String>):String {
		return lines[lines.length - 1];
	}

	static function isBalanced(code:String):Bool {
		var depth = 0;
		var inString = false;
		var strChar = "";
		var escaped = false;

		for (i in 0...code.length) {
			var c = code.charAt(i);

			if (escaped) {
				escaped = false;
				continue;
			}

			if (inString) {
				if (c == "\\") {
					escaped = true;
				} else if (c == strChar) {
					inString = false;
				}
				continue;
			}

			switch (c) {
				case '"' | "'":
					inString = true;
					strChar = c;
				case "(" | "[" | "{":
					depth++;
				case ")" | "]" | "}":
					depth--;
			}
		}

		return depth <= 0;
	}

	static function printError(error:Error):Void {
		var label = switch (error.error) {
			case SyntaxError(_): "SyntaxError";
			case IndentationError(_): "IndentationError";
			case TabError(_): "TabError";
			case NameError(_): "NameError";
			case TypeError(_): "TypeError";
			case IndexError(_): "IndexError";
			case KeyError(_): "KeyError";
			case AttributeError(_): "AttributeError";
			case ValueError(_): "ValueError";
			case ZeroDivisionError: "ZeroDivisionError";
			case RecursionError(_): "RecursionError";
			case ImportError(_): "ImportError";
			case EOFError(_): "EOFError";
			case CustomError(_): "Error";
			case NotImplementedError(_): "NotImplementedError";
		};

		var msg = error.errorMessage();
		Sys.println(color(ANSI_RED, '${label}: ${msg}'));

		if (error.line > 0) {
			Sys.println(color(ANSI_GRAY, '  at line ${error.line}, col ${error.col} in ${error.filename}'));
		}
	}

	static function runSource(cli:CLI, source:String, filename:String):Void {
		try {
			createInterpreter(filename).run(source);
		} catch (error:Error) {
			printError(error);
			Sys.exit(1);
		} catch (error:Exception) {
			Sys.println(color(ANSI_RED, error.message));
			Sys.exit(1);
		} catch (error:Dynamic) {
			Sys.println(color(ANSI_RED, Std.string(error)));
			Sys.exit(1);
		}
	}

	static function createInterpreter(filename:String):Interpreter {
		return new Interpreter(filename);
	}

	static function readLine():Null<String> {
		try {
			return Sys.stdin().readLine();
		} catch (_:Dynamic) {
			return null;
		}
	}

	static function color(c:String, s:String):String {
		return c + s + ANSI_RESET;
	}
}
