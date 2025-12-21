package hython;

import hython.Expr;
import hython.Lexer;
import hython.Lexer.Token;
import hython.Lexer.TokenType;

class PythonParser {
	private var tokens:Array<Token>;
	private var pos:Int = 0;

	public function new() {}

	public function parseString(input:String):Expr {
		var lexer = new Lexer(input);
		tokens = lexer.tokenize();
		pos = 0;
		skipNewlines();
		return parseModule();
	}

	private function parseModule():Expr {
		var statements:Array<Expr> = [];

		while (!isAtEnd()) {
			skipNewlines();
			if (isAtEnd())
				break;
			statements.push(parseStatement());
			skipNewlines();
		}

		return if (statements.length == 1) statements[0] else EBlock(statements);
	}

	private function parseStatement():Expr {
		skipNewlines();

		if (check(TDef))
			return parseFunction();
		if (check(TIf))
			return parseIf();
		if (check(TWhile))
			return parseWhile();
		if (check(TFor))
			return parseFor();
		if (check(TReturn))
			return parseReturn();
		if (check(TBreak)) {
			advance();
			consumeNewline();
			return EBreak;
		}
		if (check(TContinue)) {
			advance();
			consumeNewline();
			return EContinue;
		}
		if (check(TTry))
			return parseTry();
		if (check(TPass)) {
			advance();
			consumeNewline();
			return EConst(CInt(0)); // pass is a no-op
		}

		// Variable assignment or expression statement
		var expr = parseExpression();
		consumeNewline();
		return expr;
	}

	private function parseFunction():Expr {
		consume(TDef, "Expected 'def'");
		var name = consumeIdent("Expected function name");
		consume(TLparen, "Expected '(' after function name");

		var args:Array<Argument> = [];
		if (!check(TRparen)) {
			do {
				var argName = consumeIdent("Expected parameter name");
				var opt = false;
				var defaultValue:Expr = null;

				args.push({
					name: argName,
					t: null,
					opt: opt,
					value: defaultValue
				});
			} while (match([TComma]));
		}

		consume(TRparen, "Expected ')' after parameters");
		consume(TColon, "Expected ':' after function signature");
		consumeNewline();

		var body = parseBlock();

		return EFunction(args, body, name, null);
	}

	private function parseIf():Expr {
		consume(TIf, "Expected 'if'");
		var cond = parseExpression();
		consume(TColon, "Expected ':' after if condition");
		consumeNewline();

		var thenBlock = parseBlock();
		var elseBlock:Expr = null;

		skipNewlines();

		if (check(TElif)) {
			advance();
			var elifCond = parseExpression();
			consume(TColon, "Expected ':' after elif condition");
			consumeNewline();
			var elifBlock = parseBlock();
			skipNewlines();

			// Handle additional elif/else
			var elifElse:Expr = null;
			if (check(TElif)) {
				elifElse = parseIfContinuation();
			} else if (check(TElse)) {
				advance();
				consume(TColon, "Expected ':' after else");
				consumeNewline();
				elifElse = parseBlock();
			}
			elseBlock = EIf(elifCond, elifBlock, elifElse);
		} else if (check(TElse)) {
			advance();
			consume(TColon, "Expected ':' after else");
			consumeNewline();
			elseBlock = parseBlock();
		}

		return EIf(cond, thenBlock, elseBlock);
	}

	private function parseIfContinuation():Expr {
		advance(); // consume elif
		var cond = parseExpression();
		consume(TColon, "Expected ':' after elif condition");
		consumeNewline();

		var thenBlock = parseBlock();
		var elseBlock:Expr = null;

		skipNewlines();

		if (check(TElif)) {
			elseBlock = parseIfContinuation();
		} else if (check(TElse)) {
			advance();
			consume(TColon, "Expected ':' after else");
			consumeNewline();
			elseBlock = parseBlock();
		}

		return EIf(cond, thenBlock, elseBlock);
	}

	private function parseWhile():Expr {
		consume(TWhile, "Expected 'while'");
		var cond = parseExpression();
		consume(TColon, "Expected ':' after while condition");
		consumeNewline();

		var body = parseBlock();

		return EWhile(cond, body);
	}

	private function parseFor():Expr {
		consume(TFor, "Expected 'for'");
		var varName = consumeIdent("Expected variable name");
		consume(TIn, "Expected 'in' in for loop");
		var iter = parseExpression();
		consume(TColon, "Expected ':' after for");
		consumeNewline();

		var body = parseBlock();

		return EFor(varName, iter, body);
	}

	private function parseReturn():Expr {
		consume(TReturn, "Expected 'return'");

		var value:Expr = null;
		if (!check(TNewline) && !isAtEnd()) {
			value = parseExpression();
		}

		consumeNewline();
		return EReturn(value);
	}

	private function parseTry():Expr {
		consume(TTry, "Expected 'try'");
		consume(TColon, "Expected ':' after try");
		consumeNewline();

		var tryBlock = parseBlock();
		var varName = "";
		var catchBlock:Expr = null;

		skipNewlines();

		if (check(TExcept)) {
			advance();
			// Parse 'except' with optional exception type and variable
			if (!check(TColon)) {
				skipIdent(); // Skip exception type for now
				if (match([TAs])) {
					varName = consumeIdent("Expected variable name after 'as'");
				}
			}
			consume(TColon, "Expected ':' after except");
			consumeNewline();
			catchBlock = parseBlock();
		} else if (check(TElif)) {
			// Handle elif after try/except
			advance();
			var elifCond = parseExpression();
			consume(TColon, "Expected ':' after elif condition");
			consumeNewline();
			var elifBlock = parseBlock();
			catchBlock = EIf(elifCond, elifBlock, null);
		}

		return ETry(tryBlock, varName, null, if (catchBlock != null) catchBlock else EConst(CInt(0)));
	}

	private function parseBlock():Expr {
		consume(TIndent, "Expected indented block");

		var statements:Array<Expr> = [];

		while (!check(TDedent) && !isAtEnd()) {
			skipNewlines();
			if (check(TDedent))
				break;
			statements.push(parseStatement());
		}

		consume(TDedent, "Expected dedent after block");
		skipNewlines();

		return if (statements.length == 1) statements[0] else EBlock(statements);
	}

	private function parseExpression():Expr {
		return parseAssignment();
	}

	private function parseAssignment():Expr {
		var expr = parseOrExpression();

		if (match([TAssign])) {
			var value = parseAssignment();
			return switch (expr) {
				case EIdent(name):
					EVar(name, null, value);
				case EField(obj, field):
					EBinop("=", expr, value);
				case EArray(arr, index):
					EBinop("=", expr, value);
				default:
					error("Invalid assignment target");
					EConst(CInt(0)); // Unreachable but required by type system
			};
		} else if (match([TPlusAssign])) {
			var value = parseAssignment();
			return EBinop("+=", expr, value);
		} else if (match([TMinusAssign])) {
			var value = parseAssignment();
			return EBinop("-=", expr, value);
		} else if (match([TStarAssign])) {
			var value = parseAssignment();
			return EBinop("*=", expr, value);
		} else if (match([TSlashAssign])) {
			var value = parseAssignment();
			return EBinop("/=", expr, value);
		}

		return expr;
	}

	private function parseOrExpression():Expr {
		var expr = parseAndExpression();

		while (match([TOr])) {
			var right = parseAndExpression();
			expr = EBinop("or", expr, right);
		}

		return expr;
	}

	private function parseAndExpression():Expr {
		var expr = parseNotExpression();

		while (match([TAnd])) {
			var right = parseNotExpression();
			expr = EBinop("and", expr, right);
		}

		return expr;
	}

	private function parseNotExpression():Expr {
		if (match([TNot])) {
			var expr = parseNotExpression();
			return EUnop("not", true, expr);
		}

		return parseComparison();
	}

	private function parseComparison():Expr {
		var expr = parseBitwiseOr();

		while (true) {
			if (match([TEq])) {
				var right = parseBitwiseOr();
				expr = EBinop("==", expr, right);
			} else if (match([TNeq])) {
				var right = parseBitwiseOr();
				expr = EBinop("!=", expr, right);
			} else if (match([TLt])) {
				var right = parseBitwiseOr();
				expr = EBinop("<", expr, right);
			} else if (match([TGt])) {
				var right = parseBitwiseOr();
				expr = EBinop(">", expr, right);
			} else if (match([TLte])) {
				var right = parseBitwiseOr();
				expr = EBinop("<=", expr, right);
			} else if (match([TGte])) {
				var right = parseBitwiseOr();
				expr = EBinop(">=", expr, right);
			} else {
				break;
			}
		}

		return expr;
	}

	private function parseBitwiseOr():Expr {
		var expr = parseBitwiseXor();

		while (match([TPipe])) {
			var right = parseBitwiseXor();
			expr = EBinop("|", expr, right);
		}

		return expr;
	}

	private function parseBitwiseXor():Expr {
		var expr = parseBitwiseAnd();

		while (match([TCaret])) {
			var right = parseBitwiseAnd();
			expr = EBinop("^", expr, right);
		}

		return expr;
	}

	private function parseBitwiseAnd():Expr {
		var expr = parseShift();

		while (match([TAmpersand])) {
			var right = parseShift();
			expr = EBinop("&", expr, right);
		}

		return expr;
	}

	private function parseShift():Expr {
		var expr = parseAddition();

		while (true) {
			if (match([TLshift])) {
				var right = parseAddition();
				expr = EBinop("<<", expr, right);
			} else if (match([TRshift])) {
				var right = parseAddition();
				expr = EBinop(">>", expr, right);
			} else {
				break;
			}
		}

		return expr;
	}

	private function parseAddition():Expr {
		var expr = parseMultiplication();

		while (true) {
			if (match([TPlus])) {
				var right = parseMultiplication();
				expr = EBinop("+", expr, right);
			} else if (match([TMinus])) {
				var right = parseMultiplication();
				expr = EBinop("-", expr, right);
			} else {
				break;
			}
		}

		return expr;
	}

	private function parseMultiplication():Expr {
		var expr = parseUnary();

		while (true) {
			if (match([TStar])) {
				var right = parseUnary();
				expr = EBinop("*", expr, right);
			} else if (match([TSlash])) {
				var right = parseUnary();
				expr = EBinop("/", expr, right);
			} else if (match([TDoubleSlash])) {
				var right = parseUnary();
				expr = EBinop("//", expr, right);
			} else if (match([TPercent])) {
				var right = parseUnary();
				expr = EBinop("%", expr, right);
			} else {
				break;
			}
		}

		return expr;
	}

	private function parseUnary():Expr {
		if (match([TMinus])) {
			var expr = parseUnary();
			return EUnop("-", true, expr);
		}
		if (match([TPlus])) {
			var expr = parseUnary();
			return EUnop("+", true, expr);
		}
		if (match([TTilde])) {
			var expr = parseUnary();
			return EUnop("~", true, expr);
		}

		return parsePower();
	}

	private function parsePower():Expr {
		var expr = parsePostfix();

		if (match([TDoubleStar])) {
			var right = parseUnary();
			expr = EBinop("**", expr, right);
		}

		return expr;
	}

	private function parsePostfix():Expr {
		var expr = parsePrimary();

		while (true) {
			if (match([TLparen])) {
				// Function call
				var args:Array<Expr> = [];
				if (!check(TRparen)) {
					do {
						args.push(parseExpression());
					} while (match([TComma]));
				}
				consume(TRparen, "Expected ')' after arguments");
				expr = ECall(expr, args);
			} else if (match([TLbracket])) {
				// Array/map access
				var index = parseExpression();
				consume(TRbracket, "Expected ']' after index");
				expr = EArray(expr, index);
			} else if (match([TDot])) {
				// Field access
				var field = consumeIdent("Expected field name after '.'");
				expr = EField(expr, field);
			} else {
				break;
			}
		}

		return expr;
	}

	private function parsePrimary():Expr {
		switch (peek().type) {
			case TInt(value):
				advance();
				return EConst(CInt(value));

			case TFloat(value):
				advance();
				return EConst(CFloat(value));

			case TString(value):
				advance();
				return EConst(CString(value));

			case TTrue:
				advance();
				return EIdent("true");

			case TFalse:
				advance();
				return EIdent("false");

			case TNone:
				advance();
				return EIdent("null");

			case TIdent(name):
				advance();
				return EIdent(name);

			case TLparen:
				advance();
				var expr = parseExpression();
				consume(TRparen, "Expected ')' after expression");
				return EParent(expr);

			case TLbracket:
				advance();
				var elements:Array<Expr> = [];
				if (!check(TRbracket)) {
					do {
						elements.push(parseExpression());
					} while (match([TComma]));
				}
				consume(TRbracket, "Expected ']' after list");
				return EArrayDecl(elements);

			case TLbrace:
				advance();
				var fields:Array<{name:String, e:Expr}> = [];
				if (!check(TRbrace)) {
					do {
						var key:String;
						// Parse key as either identifier or string
						if (peek().type.getParameters().length > 0) {
							// It's a token with parameters (like TString)
							switch (peek().type) {
								case TString(s):
									key = s;
									advance();
								default:
									key = consumeIdent("Expected key in dictionary");
							}
						} else {
							key = consumeIdent("Expected key in dictionary");
						}
						consume(TColon, "Expected ':' after key");
						var value = parseExpression();
						fields.push({name: key, e: value});
					} while (match([TComma]));
				}
				consume(TRbrace, "Expected '}' after dictionary");
				return EObject(fields);

			case TLambda:
				advance();
				var args:Array<Argument> = [];
				if (!check(TColon)) {
					do {
						var argName = consumeIdent("Expected parameter name");
						args.push({
							name: argName,
							t: null,
							opt: false,
							value: null
						});
					} while (match([TComma]));
				}
				consume(TColon, "Expected ':' in lambda");
				var body = parseExpression();
				return EFunction(args, body, null, null);

			default:
				error("Unexpected token: " + peek().lexeme);
				return null;
		}
	}

	// Helper methods

	private function match(types:Array<TokenType>):Bool {
		for (type in types) {
			if (check(type)) {
				advance();
				return true;
			}
		}
		return false;
	}

	private function check(type:TokenType):Bool {
		if (isAtEnd())
			return false;
		return compareTokenTypes(peek().type, type);
	}

	private function compareTokenTypes(a:TokenType, b:TokenType):Bool {
		return Type.enumIndex(a) == Type.enumIndex(b);
	}

	private function advance():Token {
		if (!isAtEnd())
			pos++;
		return previous();
	}

	private function isAtEnd():Bool {
		return peek().type == TEOF;
	}

	private function peek():Token {
		return tokens[pos];
	}

	private function previous():Token {
		return tokens[pos - 1];
	}

	private function consume(type:TokenType, message:String):Token {
		if (check(type))
			return advance();
		error(message);
		return null;
	}

	private function consumeIdent(message:String):String {
		var token = peek();
		switch (token.type) {
			case TIdent(name):
				advance();
				return name;
			default:
				error(message);
				return "";
		}
	}

	private function skipIdent() {
		if (peek().type.getParameters().length > 0 || check(TIdent("_"))) {
			advance();
		}
	}

	private function consumeNewline() {
		skipNewlines();
	}

	private function skipNewlines() {
		while (check(TNewline)) {
			advance();
		}
	}

	private function error(message:String):Expr {
		var token = peek();
		throw 'Parse error at line ${token.line}, column ${token.column}: $message';
		return null;
	}
}
