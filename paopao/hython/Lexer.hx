package paopao.hython;

enum TokenType {
	// Literals
	TInt(value:Int);
	TFloat(value:Float);
	TString(value:String);
	TIdent(value:String);

	// Keywords
	TDef;
	TReturn;
	TIf;
	TElif;
	TElse;
	TWhile;
	TFor;
	TIn;
	TBreak;
	TContinue;
	TPass;
	TTrue;
	TFalse;
	TNone;
	TAnd;
	TOr;
	TNot;
	TClass;
	TTry;
	TExcept;
	TFinally;
	TRaise;
	TImport;
	TFrom;
	TAs;
	TGlobal;
	TLambda;
	TWith;
	TYield;
	TDel;
	TAssert;
	TAsync;
	TAwait;
	TMatch;
	TCase;
	TIs;
	TNotIn;
	TWalrus;

	// Operators
	TPlus;
	TMinus;
	TStar;
	TSlash;
	TPercent;
	TDoubleStar;
	TDoubleSlash;
	TEq;
	TNeq;
	TLt;
	TGt;
	TLte;
	TGte;
	TAssign;
	TPlusAssign;
	TMinusAssign;
	TStarAssign;
	TSlashAssign;
	TDoubleSlashAssign;
	TPercentAssign;
	TAmpersand;
	TPipe;
	TCaret;
	TTilde;
	TLshift;
	TRshift;

	// Delimiters
	TLparen;
	TRparen;
	TLbracket;
	TRbracket;
	TLbrace;
	TRbrace;
	TColon;
	TSemicolon;
	TComma;
	TDot;
	TArrow;
	TDotDotDot;

	// Special
	TNewline;
	TIndent;
	TDedent;
	TEOF;
	TError(msg:String);
}

typedef Token = {
	type:TokenType,
	line:Int,
	column:Int,
	lexeme:String
}

class Lexer {
	private var input:String;
	private var pos:Int = 0;
	private var line:Int = 1;
	private var column:Int = 1;
	private var tokens:Array<Token> = [];
	private var indentStack:Array<Int> = [0];
	private var atLineStart:Bool = true;

	// Track nesting depth for implicit line joining
	private var parenDepth:Int = 0;
	private var bracketDepth:Int = 0;
	private var braceDepth:Int = 0;

	private static var KEYWORDS:Map<String, TokenType> = [
		"def" => TDef,
		"return" => TReturn,
		"if" => TIf,
		"elif" => TElif,
		"else" => TElse,
		"while" => TWhile,
		"for" => TFor,
		"in" => TIn,
		"break" => TBreak,
		"continue" => TContinue,
		"pass" => TPass,
		"True" => TTrue,
		"False" => TFalse,
		"None" => TNone,
		"and" => TAnd,
		"or" => TOr,
		"not" => TNot,
		"class" => TClass,
		"try" => TTry,
		"except" => TExcept,
		"finally" => TFinally,
		"raise" => TRaise,
		"import" => TImport,
		"from" => TFrom,
		"as" => TAs,
		"global" => TGlobal,
		"lambda" => TLambda,
		"with" => TWith,
		"yield" => TYield,
		"del" => TDel,
		"assert" => TAssert,
		"async" => TAsync,
		"await" => TAwait,
		"match" => TMatch,
		"case" => TCase,
		"is" => TIs,
	];

	public function new(input:String) {
		this.input = input;
	}

	public function tokenize():Array<Token> {
		tokens = [];
		indentStack = [0];
		atLineStart = true;
		pos = 0;
		line = 1;
		column = 1;
		parenDepth = 0;
		bracketDepth = 0;
		braceDepth = 0;

		while (pos < input.length) {
			// Only handle indentation when not inside parens/brackets/braces
			if (atLineStart && !isEof() && !isInsideDelimiters()) {
				handleIndentation();
			}

			skipWhitespace();

			if (isEof())
				break;

			var ch = peek();

			// Comments
			if (ch == '#') {
				skipComment();
				continue;
			}

			// Newline - skip if inside delimiters (implicit line joining)
			if (ch == '\n') {
				advance();
				if (!isInsideDelimiters()) {
					atLineStart = true;
					addToken(TNewline, "\n");
				}
				continue;
			}

			atLineStart = false;

			// Strings
			if (ch == '"' || ch == "'") {
				tokenizeString();
				continue;
			}

			// Numbers
			if (isDigit(ch)) {
				tokenizeNumber();
				continue;
			}

			// Check for "not in" before identifiers
			if (ch == 'n' && peekAhead(1) == 'o' && peekAhead(2) == 't') {
				var savedPos = pos;
				var savedLine = line;
				var savedCol = column;
				advance(); // 'n'
				advance(); // 'o'
				advance(); // 't'
				skipWhitespace();
				if (peek() == 'i' && peekAhead(1) == 'n' && !isAlphaNum(peekAhead(2))) {
					advance(); // 'i'
					advance(); // 'n'
					addToken(TNotIn, "not in");
					continue;
				} else {
					// Rollback and parse as "not" keyword
					pos = savedPos;
					line = savedLine;
					column = savedCol;
				}
			}

			// Identifiers and keywords
			if (isAlpha(ch) || ch == '_') {
				tokenizeIdentOrKeyword();
				continue;
			}

			// Operators and delimiters
			if (!tokenizeOperatorOrDelimiter()) {
				addToken(TError("Unexpected character: " + ch), ch);
				advance();
			}
		}

		// Handle remaining dedents
		while (indentStack.length > 1) {
			indentStack.pop();
			addToken(TDedent, "");
		}

		addToken(TEOF, "");
		return tokens;
	}

	private function isInsideDelimiters():Bool {
		return parenDepth > 0 || bracketDepth > 0 || braceDepth > 0;
	}

	private function handleIndentation() {
		var indentLevel = 0; // Count spaces on current line

		// Count the spaces/tabs
		while (pos < input.length && (peek() == ' ' || peek() == '\t')) {
			if (peek() == ' ') {
				indentLevel++; // Each space = 1
			} else {
				indentLevel += 4; // Each tab = 4
			}
			advance();
		}

		var currentIndent = indentStack[indentStack.length - 1];

		if (indentLevel > currentIndent) {
			// Going deeper: Level 0→1 or 1→2
			indentStack.push(indentLevel);
			addToken(TIndent, "");
		} else if (indentLevel < currentIndent) {
			// Going back out: Level 2→1 or 1→0
			while (indentStack.length > 1 && indentStack[indentStack.length - 1] > indentLevel) {
				indentStack.pop();
				addToken(TDedent, "");
			}
		}
	}

	private function skipWhitespace() {
		while (!isEof() && (peek() == ' ' || peek() == '\t' || peek() == '\r')) {
			advance();
		}
	}

	private function skipComment() {
		while (!isEof() && peek() != '\n') {
			advance();
		}
	}

	private function tokenizeString() {
		var quote = peek();
		var startLine = line;
		var startCol = column;
		var isFString = false;

		// Check for f-string prefix (f" or f')
		if (peek() == 'f' || peek() == 'F') {
			var next = peekAhead(1);
			if (next == '"' || next == "'") {
				isFString = true;
				advance(); // Skip 'f'
				quote = next;
			}
		}

		advance(); // Skip opening quote

		var value = "";
		var isTriple = false;

		// Check for triple-quoted string
		if (peek() == quote && peekAhead(1) == quote) {
			isTriple = true;
			advance();
			advance();
		}

		// For f-strings, we'll store the raw string and parse expressions later
		if (isFString) {
			value = "f";
		}

		while (!isEof()) {
			if (isTriple) {
				if (peek() == quote && peekAhead(1) == quote && peekAhead(2) == quote) {
					advance();
					advance();
					advance();
					break;
				}
			} else {
				if (peek() == quote) {
					advance();
					break;
				}
				if (peek() == '\n') {
					addToken(TError("Unterminated string"), value);
					return;
				}
			}

			if (peek() == '\\') {
				advance();
				if (!isEof()) {
					var escaped = peek();
					value += switch (escaped) {
						case 'n': '\n';
						case 't': '\t';
						case 'r': '\r';
						case '\\': '\\';
						case '"': '"';
						case "'": "'";
						case '0': '\x00';
						default: escaped;
					};
					advance();
				}
			} else {
				value += peek();
				advance();
			}
		}

		addToken(TString(value), quote + value + quote);
	}

	private function tokenizeNumber() {
		var value = "";
		var isFloat = false;

		while (!isEof() && isDigit(peek())) {
			value += peek();
			advance();
		}

		if (peek() == '.' && isDigit(peekAhead(1))) {
			isFloat = true;
			value += '.';
			advance();
			while (!isEof() && isDigit(peek())) {
				value += peek();
				advance();
			}
		}

		if (peek() == 'e' || peek() == 'E') {
			isFloat = true;
			value += peek();
			advance();
			if (peek() == '+' || peek() == '-') {
				value += peek();
				advance();
			}
			while (!isEof() && isDigit(peek())) {
				value += peek();
				advance();
			}
		}

		if (isFloat) {
			addToken(TFloat(Std.parseFloat(value)), value);
		} else {
			addToken(TInt(Std.parseInt(value)), value);
		}
	}

	private function tokenizeIdentOrKeyword() {
		var value = "";

		while (!isEof() && (isAlphaNum(peek()) || peek() == '_')) {
			value += peek();
			advance();
		}

		var tokenType = KEYWORDS.get(value);
		if (tokenType == null) {
			tokenType = TIdent(value);
		}

		addToken(tokenType, value);
	}

	private function tokenizeOperatorOrDelimiter():Bool {
		var ch = peek();
		var next = peekAhead(1);
		var next2 = peekAhead(2);

		if (ch == '#') {
			while (!isEof() && peek() != '\n') {
				advance();
			}
			return true;
		}

		// Three-character operators
		if (ch == '.' && next == '.' && next2 == '.') {
			advance();
			advance();
			advance();
			addToken(TDotDotDot, "...");
			return true;
		}

		if (ch == '/' && next == '/' && next2 == '=') {
			advance();
			advance();
			advance();
			addToken(TDoubleSlashAssign, "//=");
			return true;
		}

		// Handle "not in" as a single operator
		if (ch == 'n' && next == 'o' && next2 == 't') {
			var savedPos = pos;
			var savedLine = line;
			var savedCol = column;
			advance(); // 'n'
			advance(); // 'o'
			advance(); // 't'
			skipWhitespace();
			if (peek() == 'i' && peekAhead(1) == 'n' && !isAlphaNum(peekAhead(2))) {
				advance(); // 'i'
				advance(); // 'n'
				addToken(TNotIn, "not in");
				return true;
			} else {
				// Rollback and let it be parsed as "not" keyword
				pos = savedPos;
				line = savedLine;
				column = savedCol;
			}
		}

		if (ch == '*' && next == '*') {
			advance();
			advance();
			addToken(TDoubleStar, "**");
			return true;
		}

		if (ch == '/' && next == '/') {
			advance();
			advance();
			addToken(TDoubleSlash, "//");
			return true;
		}

		if (ch == '<' && next == '<') {
			advance();
			advance();
			addToken(TLshift, "<<");
			return true;
		}

		if (ch == '>' && next == '>') {
			advance();
			advance();
			addToken(TRshift, ">>");
			return true;
		}

		if (ch == '=' && next == '=') {
			advance();
			advance();
			addToken(TEq, "==");
			return true;
		}

		if (ch == '!' && next == '=') {
			advance();
			advance();
			addToken(TNeq, "!=");
			return true;
		}

		if (ch == '<' && next == '=') {
			advance();
			advance();
			addToken(TLte, "<=");
			return true;
		}

		if (ch == '>' && next == '=') {
			advance();
			advance();
			addToken(TGte, ">=");
			return true;
		}

		if (ch == '+' && next == '=') {
			advance();
			advance();
			addToken(TPlusAssign, "+=");
			return true;
		}

		if (ch == '-' && next == '=') {
			advance();
			advance();
			addToken(TMinusAssign, "-=");
			return true;
		}

		if (ch == '*' && next == '=') {
			advance();
			advance();
			addToken(TStarAssign, "*=");
			return true;
		}

		if (ch == '/' && next == '=') {
			advance();
			advance();
			addToken(TSlashAssign, "/=");
			return true;
		}

		if (ch == '%' && next == '=') {
			advance();
			advance();
			addToken(TPercentAssign, "%=");
			return true;
		}

		if (ch == '-' && next == '>') {
			advance();
			advance();
			addToken(TArrow, "->");
			return true;
		}

		if (ch == ':' && next == '=') {
			advance();
			advance();
			addToken(TWalrus, ":=");
			return true;
		}

		// Single-character operators and delimiters
		switch (ch) {
			case '+':
				advance();
				addToken(TPlus, "+");
				return true;
			case '-':
				advance();
				addToken(TMinus, "-");
				return true;
			case '*':
				advance();
				addToken(TStar, "*");
				return true;
			case '/':
				advance();
				addToken(TSlash, "/");
				return true;
			case '%':
				advance();
				addToken(TPercent, "%");
				return true;
			case '=':
				advance();
				addToken(TAssign, "=");
				return true;
			case '<':
				advance();
				addToken(TLt, "<");
				return true;
			case '>':
				advance();
				addToken(TGt, ">");
				return true;
			case '&':
				advance();
				addToken(TAmpersand, "&");
				return true;
			case '|':
				advance();
				addToken(TPipe, "|");
				return true;
			case '^':
				advance();
				addToken(TCaret, "^");
				return true;
			case '~':
				advance();
				addToken(TTilde, "~");
				return true;
			case '(':
				advance();
				parenDepth++;
				addToken(TLparen, "(");
				return true;
			case ')':
				advance();
				parenDepth--;
				addToken(TRparen, ")");
				return true;
			case '[':
				advance();
				bracketDepth++;
				addToken(TLbracket, "[");
				return true;
			case ']':
				advance();
				bracketDepth--;
				addToken(TRbracket, "]");
				return true;
			case '{':
				advance();
				braceDepth++;
				addToken(TLbrace, "{");
				return true;
			case '}':
				advance();
				braceDepth--;
				addToken(TRbrace, "}");
				return true;
			case ':':
				advance();
				addToken(TColon, ":");
				return true;
			case ';':
				advance();
				addToken(TSemicolon, ";");
				return true;
			case ',':
				advance();
				addToken(TComma, ",");
				return true;
			case '.':
				advance();
				addToken(TDot, ".");
				return true;
			default:
				return false;
		}
	}

	private function addToken(type:TokenType, lexeme:String) {
		tokens.push({
			type: type,
			line: line,
			column: column,
			lexeme: lexeme
		});
	}

	private function peek():String {
		if (isEof())
			return '\x00';
		return input.charAt(pos);
	}

	private function peekAhead(n:Int):String {
		if (pos + n >= input.length)
			return '\x00';
		return input.charAt(pos + n);
	}

	private function advance():String {
		var ch = peek();
		pos++;
		if (ch == '\n') {
			line++;
			column = 1;
		} else {
			column++;
		}
		return ch;
	}

	private function isEof():Bool {
		return pos >= input.length;
	}

	private function isDigit(ch:String):Bool {
		return ch >= '0' && ch <= '9';
	}

	private function isAlpha(ch:String):Bool {
		return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_';
	}

	private function isAlphaNum(ch:String):Bool {
		return isAlpha(ch) || isDigit(ch);
	}
}
