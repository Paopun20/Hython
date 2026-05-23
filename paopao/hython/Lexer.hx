// This file defines the Lexer for the Python language (CPython-aligned).
// The lexer converts source code into a stream of tokens.
// It handles indentation-based blocks, Python keywords, literals, and operators.
// Unlike C-style languages, whitespace and indentation are significant.
package paopao.hython;

import paopao.hython.Error;
import String as HxString;

// Token Definition
enum Token {
	// Identifiers & literals
	TIdent(value:String);
	TInt(value:Int);
	TFloat(value:Float);
	TString(value:String);

	// Operators (Python-native only)
	TPlus; // +
	TMinus; // -
	TMul; // *
	TDiv; // /
	TMod; // %

	TEqual; // =
	TEqualEqual; // ==
	TNotEqual; // !=

	TLess; // <
	TGreater; // >
	TLessEqual; // <=
	TGreaterEqual; // >=

	TAnd; // and
	TOr; // or
	TNot; // not

	// Symbols
	TLParen;
	TRParen;
	TLBracket;
	TRBracket;
	TComma;
	TDot;
	TColon;

	// Indentation
	TIndent;
	TDedent;
	TNewline;

	// Keywords
	TIf;
	TElif;
	TElse;
	TWhile;
	TFor;
	TIn;
	TDef;
	TReturn;
	TImport;
	TFrom;
	TAs;
	TPass;
	TBreak;
	TContinue;

	// End of file
	TEOF;
}

// Lexer

@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class Lexer {
	public var source:String;
	public var tokens:Array<Token>;
	public var tokenPositions:Array<TokenPos>;
	public var pos:Int;
	public var line:Int;
	public var col:Int;

	private var indentStack:Array<Int>;
	private var pendingTokens:Array<Token>;
	private var pendingTokenPositions:Array<TokenPos>;
	private var atLineStart:Bool;

	public function new(source:String) {
		this.source = source;
		this.tokens = [];
		this.tokenPositions = [];
		this.pos = 0;
		this.line = 1;
		this.col = 1;

		this.indentStack = [0];
		this.pendingTokens = [];
		this.pendingTokenPositions = [];
		this.atLineStart = true;
	}

	public function tokenize():Array<Token> {
		while (true) {
			var token = nextToken();
			tokens.push(token);
			tokenPositions.push(lastTokenPos);
			if (token == TEOF)
				break;
		}
		return tokens;
	}

	public var lastTokenPos(default, null):TokenPos;

	// Helpers zone functions for peeking, advancing, and character classification

	private function peek(offset:Int = 0):String {
		var index = pos + offset;
		if (index >= source.length)
			return HxString.fromCharCode(0);
		return source.charAt(index);
	}

	private function advance():String {
		var ch = peek();
		pos++;

		if (ch == "\n") {
			line++;
			col = 1;
		} else {
			col++;
		}

		return ch;
	}

	private function isDigit(ch:String):Bool {
		return ch >= "0" && ch <= "9";
	}

	private function isAlpha(ch:String):Bool {
		return (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") || ch == "_";
	}

	private function isAlphaNumeric(ch:String):Bool {
		return isAlpha(ch) || isDigit(ch);
	}

	// Whitespace & Comments

	private function skipWhitespace():Void {
		while (true) {
			var ch = peek();

			if (ch == " " || ch == "\t" || ch == "\r") {
				advance();
			} else if (ch == "#") {
				while (peek() != "\n" && peek() != HxString.fromCharCode(0)) {
					advance();
				}
			} else {
				break;
			}
		}
	}

	// Indentation Handling (Python-style)

	private function processIndentation():Void {
		var count = 0;

		while (peek(count) == " ")
			count++;

		var nextCh = peek(count);

		// Skip blank / comment-only lines
		if (nextCh == "\n" || nextCh == "#" || nextCh == HxString.fromCharCode(0))
			return;

		for (i in 0...count)
			advance();

		var current = indentStack[indentStack.length - 1];

		if (count > current) {
			indentStack.push(count);
			pendingTokens.push(TIndent);
			pendingTokenPositions.push(makePos(line, col));
		} else if (count < current) {
			while (indentStack[indentStack.length - 1] != count) {
				if (indentStack.length <= 1) {
					throw new Error(IndentationError("invalid dedent"), line, col);
				}
				indentStack.pop();
				pendingTokens.push(TDedent);
				pendingTokenPositions.push(makePos(line, col));
			}
		}
	}

	// Readers

	private function readString(quote:String):Token {
		var value = "";
		advance();

		while (peek() != quote && peek() != HxString.fromCharCode(0)) {
			if (peek() == "\\") {
				advance();
				var esc = advance();
				switch (esc) {
					case "n":
						value += "\n";
					case "t":
						value += "\t";
					case "r":
						value += "\r";
					default:
						value += esc;
				}
			} else {
				value += advance();
			}
		}

		if (peek() == quote)
			advance();
		return TString(value);
	}

	private function readNumber():Token {
		var value = "";
		var isFloat = false;

		while (isDigit(peek()))
			value += advance();

		if (peek() == "." && isDigit(peek(1))) {
			isFloat = true;
			value += advance();
			while (isDigit(peek()))
				value += advance();
		}

		return isFloat ? TFloat(Std.parseFloat(value)) : TInt(Std.parseInt(value));
	}

	private function readIdentifier():Token {
		var value = "";

		while (isAlphaNumeric(peek()))
			value += advance();

		return switch (value) {
			case "if": TIf;
			case "elif": TElif;
			case "else": TElse;
			case "while": TWhile;
			case "for": TFor;
			case "in": TIn;
			case "def": TDef;
			case "return": TReturn;
			case "import": TImport;
			case "from": TFrom;
			case "as": TAs;
			case "and": TAnd;
			case "or": TOr;
			case "not": TNot;
			case "pass": TPass;
			case "break": TBreak;
			case "continue": TContinue;
			default: TIdent(value);
		};
	}

	// Tokenization

	public function nextToken():Token {
		if (pendingTokens.length > 0) {
			lastTokenPos = pendingTokenPositions.shift();
			return pendingTokens.shift();
		}

		if (atLineStart) {
			atLineStart = false;
			processIndentation();
			if (pendingTokens.length > 0) {
				lastTokenPos = pendingTokenPositions.shift();
				return pendingTokens.shift();
			}
		}

		skipWhitespace();

		if (pos >= source.length) {
			if (indentStack.length > 1) {
				indentStack.pop();
				lastTokenPos = makePos(line, col);
				return TDedent;
			}
			lastTokenPos = makePos(line, col);
			return TEOF;
		}

		var ch = peek();
		var startLine = line;
		var startCol = col;

		if (ch == "\n") {
			advance();
			atLineStart = true;
			lastTokenPos = makePos(startLine, startCol);
			return TNewline;
		}

		if (ch == '"' || ch == "'") {
			var t = readString(ch);
			lastTokenPos = makePos(startLine, startCol);
			return t;
		}
		if (isDigit(ch)) {
			var t = readNumber();
			lastTokenPos = makePos(startLine, startCol);
			return t;
		}
		if (isAlpha(ch)) {
			var t = readIdentifier();
			lastTokenPos = makePos(startLine, startCol);
			return t;
		}

		advance();

		switch (ch) {
			case "+":
				lastTokenPos = makePos(startLine, startCol);
				return TPlus;
			case "-":
				lastTokenPos = makePos(startLine, startCol);
				return TMinus;
			case "*":
				lastTokenPos = makePos(startLine, startCol);
				return TMul;
			case "/":
				lastTokenPos = makePos(startLine, startCol);
				return TDiv;
			case "%":
				lastTokenPos = makePos(startLine, startCol);
				return TMod;

			case "=":
				if (peek() == "=") {
					advance();
					lastTokenPos = makePos(startLine, startCol);
					return TEqualEqual;
				}
				lastTokenPos = makePos(startLine, startCol);
				return TEqual;

			case "!":
				if (peek() == "=") {
					advance();
					return TNotEqual;
				}
				throw new Error(SyntaxError("unexpected '!'"), line, col);

			case "<":
				if (peek() == "=") {
					advance();
					lastTokenPos = makePos(startLine, startCol);
					return TLessEqual;
				}
				lastTokenPos = makePos(startLine, startCol);
				return TLess;

			case ">":
				if (peek() == "=") {
					advance();
					lastTokenPos = makePos(startLine, startCol);
					return TGreaterEqual;
				}
				lastTokenPos = makePos(startLine, startCol);
				return TGreater;

			case "(":
				lastTokenPos = makePos(startLine, startCol);
				return TLParen;
			case ")":
				lastTokenPos = makePos(startLine, startCol);
				return TRParen;
			case "[":
				lastTokenPos = makePos(startLine, startCol);
				return TLBracket;
			case "]":
				lastTokenPos = makePos(startLine, startCol);
				return TRBracket;
			case ",":
				lastTokenPos = makePos(startLine, startCol);
				return TComma;
			case ".":
				lastTokenPos = makePos(startLine, startCol);
				return TDot;
			case ":":
				lastTokenPos = makePos(startLine, startCol);
				return TColon;

			default:
				throw new Error(SyntaxError("unexpected character: " + ch), line, col);
		}
	}

	private inline function makePos(startLine:Int, startCol:Int):TokenPos {
		return {
			line: startLine,
			col: startCol,
			colStart: startCol,
			colEnd: col - 1
		};
	}
}

typedef TokenPos = {
	var line:Int;
	var col:Int;
	var colStart:Int;
	var colEnd:Int;
}
