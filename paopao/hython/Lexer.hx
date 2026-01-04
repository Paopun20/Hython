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
	TDoubleStarAssign;
	TAmpersand;
	TPipe;
	TCaret;
	TTilde;
	TLshift;
	TRshift;
	TAt;
	TAtAssign;
	TAmpersandAssign;
	TPipeAssign;
	TCaretAssign;
	TLshiftAssign;
	TRshiftAssign;

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
				var ln = line;
				var col = column;
				advance();
				if (!isInsideDelimiters()) {
					atLineStart = true;
					addToken(TNewline, "\n");
				}
				continue;
			}

			atLineStart = false;

			// Strings
			if (isStringStart()) {
				tokenizeString();
				continue;
			}

			// Numbers
			if (isDigit(ch)) {
				tokenizeNumber();
				continue;
			}

			// Check for "not in" before identifiers
			if (ch == 'n' && matchKeywordSequence("not")) {
				var savedPos = pos;
				var savedLine = line;
				var savedCol = column;
				
				// Skip "not"
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
		var indentLevel = 0;

		// Count spaces/tabs
		while (pos < input.length && (peek() == ' ' || peek() == '\t')) {
			if (peek() == ' ') {
				indentLevel++;
			} else {
				indentLevel += 8; // Tab = 8 spaces (Python standard)
			}
			advance();
		}

		// Skip indentation handling for blank lines or comment-only lines
		if (isEof() || peek() == '\n' || peek() == '#') {
			return;
		}

		var currentIndent = indentStack[indentStack.length - 1];

		if (indentLevel > currentIndent) {
			// Increased indentation
			indentStack.push(indentLevel);
			addToken(TIndent, "");
		} else if (indentLevel < currentIndent) {
			// Decreased indentation
			while (indentStack.length > 1 && indentStack[indentStack.length - 1] > indentLevel) {
				indentStack.pop();
				addToken(TDedent, "");
			}

			// Check for indentation error
			if (indentStack[indentStack.length - 1] != indentLevel) {
				addToken(TError("Indentation error: unindent does not match any outer indentation level"), "");
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

	private function isStringStart():Bool {
		var ch = peek();
		if (ch == '"' || ch == "'")
			return true;

		// Check for string prefixes (r, f, b, u and combinations)
		var lowerCh = ch.toLowerCase();
		if (lowerCh == 'r' || lowerCh == 'f' || lowerCh == 'b' || lowerCh == 'u') {
			var next1 = peekAhead(1);
			if (next1 == '"' || next1 == "'")
				return true;

			// Two-character prefixes (rb, br, fr, rf, etc.)
			var lowerNext1 = next1.toLowerCase();
			if (lowerNext1 == 'r' || lowerNext1 == 'f' || lowerNext1 == 'b' || lowerNext1 == 'u') {
				var next2 = peekAhead(2);
				if (next2 == '"' || next2 == "'")
					return true;
			}
		}

		return false;
	}

	private function tokenizeString() {
		var startLine = line;
		var startCol = column;
		var prefix = "";

		// Collect string prefix
		while (!isEof()) {
			var ch = peek();
			var lowerCh = ch.toLowerCase();
			if (lowerCh == 'r' || lowerCh == 'f' || lowerCh == 'b' || lowerCh == 'u') {
				prefix += ch;
				advance();
			} else {
				break;
			}
		}

		if (isEof() || (peek() != '"' && peek() != "'")) {
			addToken(TError("Invalid string prefix"), prefix);
			return;
		}

		var quote = peek();
		advance(); // Skip opening quote

		var value = "";
		var isTriple = false;

		// Check for triple-quoted string
		if (peek() == quote && peekAhead(1) == quote) {
			isTriple = true;
			advance();
			advance();
		}

		// Store prefix info
		if (prefix != "") {
			value = prefix;
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
					// Only process escapes for non-raw strings
					if (prefix.toLowerCase().indexOf('r') == -1) {
						value += switch (escaped) {
							case 'n': '\n';
							case 't': '\t';
							case 'r': '\r';
							case '\\': '\\';
							case '"': '"';
							case "'": "'";
							case '0': '\x00';
							default: '\\' + escaped;
						};
					} else {
						value += '\\' + escaped;
					}
					advance();
				}
			} else {
				value += peek();
				advance();
			}
		}

		var lexeme = (prefix != "" ? prefix : "") + quote + (isTriple ? quote + quote : "") + value + (isTriple ? quote + quote + quote : quote);
		addToken(TString(value), lexeme);
	}

	private function tokenizeNumber() {
		var value = "";
		var isFloat = false;
		var startCol = column;

		// Handle binary, octal, hex prefixes
		if (peek() == '0' && !isEof()) {
			value += peek();
			advance();

			var next = !isEof() ? peek().toLowerCase() : '';

			// Binary (0b or 0B)
			if (next == 'b') {
				value += peek();
				advance();
				while (!isEof() && (peek() == '0' || peek() == '1' || peek() == '_')) {
					if (peek() != '_')
						value += peek();
					advance();
				}
				addToken(TInt(Std.parseInt(value)), value);
				return;
			}

			// Octal (0o or 0O)
			if (next == 'o') {
				value += peek();
				advance();
				while (!isEof() && peek() >= '0' && peek() <= '7') {
					value += peek();
					advance();
				}
				addToken(TInt(Std.parseInt(value)), value);
				return;
			}

			// Hexadecimal (0x or 0X)
			if (next == 'x') {
				value += peek();
				advance();
				while (!isEof() && isHexDigit(peek())) {
					value += peek();
					advance();
				}
				addToken(TInt(Std.parseInt(value)), value);
				return;
			}
		}

		// Regular decimal digits
		while (!isEof() && (isDigit(peek()) || peek() == '_')) {
			if (peek() != '_')
				value += peek();
			advance();
		}

		// Decimal point
		if (peek() == '.' && !isEof() && peekAhead(1) != null && isDigit(peekAhead(1))) {
			isFloat = true;
			value += '.';
			advance();
			while (!isEof() && (isDigit(peek()) || peek() == '_')) {
				if (peek() != '_')
					value += peek();
				advance();
			}
		}

		// Scientific notation
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

		if (ch == '*' && next == '*' && next2 == '=') {
			advance();
			advance();
			advance();
			addToken(TDoubleStarAssign, "**=");
			return true;
		}

		if (ch == '<' && next == '<' && next2 == '=') {
			advance();
			advance();
			advance();
			addToken(TLshiftAssign, "<<=");
			return true;
		}

		if (ch == '>' && next == '>' && next2 == '=') {
			advance();
			advance();
			advance();
			addToken(TRshiftAssign, ">>=");
			return true;
		}

		// Two-character operators
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

		if (ch == '&' && next == '=') {
			advance();
			advance();
			addToken(TAmpersandAssign, "&=");
			return true;
		}

		if (ch == '|' && next == '=') {
			advance();
			advance();
			addToken(TPipeAssign, "|=");
			return true;
		}

		if (ch == '^' && next == '=') {
			advance();
			advance();
			addToken(TCaretAssign, "^=");
			return true;
		}

		if (ch == '@' && next == '=') {
			advance();
			advance();
			addToken(TAtAssign, "@=");
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
			case '@':
				advance();
				addToken(TAt, "@");
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

	private function matchKeywordSequence(keyword:String):Bool {
		for (i in 0...keyword.length) {
			if (peekAhead(i) != keyword.charAt(i))
				return false;
		}
		// Make sure it's not part of a longer identifier
		var nextChar = peekAhead(keyword.length);
		return nextChar == null || !isAlphaNum(nextChar);
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

	private function isHexDigit(ch:String):Bool {
		return (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F');
	}

	private function isAlpha(ch:String):Bool {
		return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_';
	}

	private function isAlphaNum(ch:String):Bool {
		return isAlpha(ch) || isDigit(ch);
	}
}