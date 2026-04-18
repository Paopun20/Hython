// Tokenizer -> AST -> Compiler -> This VM
// This file contains the main interpreter class and related utilities for executing bytecode.
// The Interp class is responsible for managing variable scopes, executing bytecode, and handling function calls. It also includes error handling and support for built-in functions.

package paopao.hython;

import paopao.hython.Parser;
import paopao.hython.Ast;
import paopao.hython.bytecode.BytecodeCompiler;
import paopao.hython.bytecode.BytecodeDeserializer;
import haxe.io.Bytes;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
#if sys
import sys.io.File;
import sys.io.FileOutput;
#end

using StringTools;
using Lambda;
using Reflect;

@:structInit
@:nullSafety(Strict) private class IDeclaredVariable {
	public var name:VariableType;
	public var oldDeclared:Bool;
	public var oldValue:Dynamic;
}

private class BaseSignal {}
private class BreakSignal extends BaseSignal {}
private class ContinueSignal extends BaseSignal {}
private class ReturnSignal extends BaseSignal {
	public var value:Dynamic;

	public function new(value:Dynamic) {
		this.value = value;
	}
}

@:nullSafety(Strict) class Interp {
	@:isVar private var globals:Map<String, VariableType>;
	@:isVar private var natives:Map<String, VariableType>;

	public function new() {
		globals = new Map();
		natives = new Map();

		// Register built-in functions
		registerBuiltIns();
	}

	/* set var with haxe object */
	public function setVar(name:String, value:Dynamic):Void {
	}

	/* get hython variable and convert to haxe object */
	public function getVar(name:String):Dynamic {
		return null; // Placeholder - implement actual variable retrieval logic
	}

	function registerBuiltIns() {
		setVar("print", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var output = args.map(arg -> Std.string(arg)).join(" ");
			trace(output);
		}));

		setVar("len", function(x:Dynamic) {
			if (Std.is(x, String)) return (x : String).length;
			if (Std.is(x, Array)) return (x : Array<Dynamic>).length;
			return 0; // Default for unsupported types
		});	

		setVar("range", function(start:Int, end:Int) {
			var result = new Array<Dynamic>();
			for (i in start...end) {
				result.push(i);
			}
			return result;
		});
	}
}