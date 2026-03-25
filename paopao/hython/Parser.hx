package paopao.hython;

import paopao.hython.Expr;
import paopao.hython.Lexer;
import paopao.hython.Lexer.Token;
import paopao.hython.Lexer.TokenType;
import paopao.hython.Preprocessor;
import haxe.Exception;

using StringTools;

private function helper_escape(str:String):String {
	str = StringTools.replace(str, "\t", "\\t");
	str = StringTools.replace(str, "\n", "\\n");
	str = StringTools.replace(str, "\r", "\\r");
	return str;
}

class SyntaxError extends Exception {
	public function new(message:String) {
		super(message);
	}

	override public function toString():String {
		return 'SyntaxError: ${helper_escape(this.get_message())}';
	}
}

class ParseException extends Exception {
	public var line:Int;
	public var column:Int;
	public var excp:Exception;

	public function new(excp:Exception, line:Int, column:Int) {
		super(excp.message);
		this.excp = excp;
		this.line = line;
		this.column = column;
	}

	override public function toString():String {
		return '${excp} at line $line, column $column';
	}
}

@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class Parser {
	private var tokens:Array<Token>;
	private var pos:Int = 0;

	public function new() {}

	public function parseString(input:String):Expr {
		var percode = Preprocessor.preprocess(input);
		var lexer = new Lexer(percode);
		tokens = lexer.tokenize();
		pos = 0;
		skipNewlines(); // Skip leading newlines
		return parseModule();
	}

	private function parseModule():Expr {
		var statements:Array<Expr> = [];

		while (!isAtEnd()) {
			skipNewlines(); // Skip newlines between statements
			if (isAtEnd())
				break;
			statements.push(parseStatement());
			skipNewlines(); // Skip newlines after statement
		}

		return if (statements.length == 1) statements[0] else EBlock(statements);
	}

	private function parseGlobal():Expr {
		consume(TGlobal, "Expected 'global'");
		var varNames:Array<String> = [];

		// Parse comma-separated list of variable names
		do {
			skipNewlines();
			varNames.push(consumeIdent("Expected variable name"));
			skipNewlines();
		} while (match([TComma]));

		consumeNewline();
		return EGlobal(varNames);
	}

	private function parseNonLocal():Expr {
		consume(TNonLocal, "Expected 'nonlocal'");
		var varNames:Array<String> = [];

		// Parse comma-separated list of variable names
		do {
			skipNewlines();
			varNames.push(consumeIdent("Expected variable name"));
			skipNewlines();
		} while (match([TComma]));

		consumeNewline();
		return ENonLocal(varNames);
	}

	private function parseStatement():Expr {
		skipNewlines(); // Skip leading newlines for the statement

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
		if (check(TYield))
			return parseYield();
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
		if (check(TRaise))
			return parseRaise();
		if (check(TWith))
			return parseWith();
		if (check(TMatch))
			return parseMatch();
		if (check(TAsync))
			return parseAsync();
		if (check(TPass)) {
			advance();
			consumeNewline();
			return EConst(CInt(0)); // pass is a no-op
		}
		if (check(TImport))
			return parseImport();
		if (check(TFrom))
			return parseImportFrom();
		if (check(TDel))
			return parseDel();
		if (check(TAssert))
			return parseAssert();
		if (check(TClass))
			return parseClass();
		if (check(TGlobal))
			return parseGlobal();
		if (check(TNonLocal))
			return parseNonLocal();

		// Check for decorators before function/class
		var decorators:Array<Expr> = [];
		while (check(TAt)) {
			advance();
			var decorator = parseExprNoAssign();
			consumeNewline();
			decorators.push(decorator);
		}

		// Check for decorated function
		if (check(TDef)) {
			var func = parseFunction();
			if (decorators.length > 0) {
				return EDecorator(func, decorators);
			}
			return func;
		}

		// Check for decorated class
		if (check(TClass)) {
			var cls = parseClass();
			if (decorators.length > 0) {
				return EDecorator(cls, decorators);
			}
			return cls;
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

		// Allow newlines after '('
		skipNewlines();

		var args:Array<Argument> = [];
		var hasDefault = false;
		var hasVarArgs = false;
		var hasKwArgs = false;

		if (!check(TRparen)) {
			// Allow newlines before the first parameter
			skipNewlines();
			do {
				// Allow newlines before each parameter
				skipNewlines();

				// Check for *args or **kwargs
				if (match([TDoubleStar])) {
					// **kwargs
					var kwargName = consumeIdent("Expected **kwargs parameter name");
					args.push({
						name: kwargName,
						t: null,
						opt: false,
						value: null,
						isVarArgs: false,
						isKwArgs: true
					});
					hasKwArgs = true;
				} else if (match([TStar])) {
					// *args
					var varargName = consumeIdent("Expected *args parameter name");
					args.push({
						name: varargName,
						t: null,
						opt: false,
						value: null,
						isVarArgs: true,
						isKwArgs: false
					});
					hasVarArgs = true;
				} else {
					var argName = consumeIdent("Expected parameter name");
					var opt = false;
					var defaultValue:Expr = null;

					// Check for type hint
					var typeHint:CType = null;
					if (match([TColon])) {
						typeHint = parseTypeHint();
					}

					// Check for default value
					if (match([TAssign])) {
						hasDefault = true;
						defaultValue = parseExpression();
						opt = true;
					}

					args.push({
						name: argName,
						t: typeHint,
						opt: opt,
						value: defaultValue,
						isVarArgs: false,
						isKwArgs: false
					});
				}
				// Allow newlines after parsing a parameter (before potential comma or closing paren)
				skipNewlines();
			} while (match([TComma])); // This consumes the comma if present
				// Allow newlines after the last parameter (before closing paren)
			skipNewlines();
		}

		consume(TRparen, "Expected ')' after parameters");

		// Check for return type hint
		var returnType:CType = null;
		if (match([TArrow])) {
			returnType = parseTypeHint();
		}

		consume(TColon, "Expected ':' after function signature");
		consumeNewline();

		var body = parseBlock();

		return EFunction(args, body, name, returnType);
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

	private function parseYield():Expr {
		consume(TYield, "Expected 'yield'");

		var value:Expr = null;
		if (!check(TNewline) && !isAtEnd()) {
			value = parseExpression();
		}

		consumeNewline();
		return EYield(value);
	}

	private function parseTry():Expr {
		consume(TTry, "Expected 'try'");
		consume(TColon, "Expected ':' after try");
		consumeNewline();

		var tryBlock = parseBlock();
		var excepts:Array<{type:Expr, varName:String, body:Expr}> = [];
		var finallyBlock:Expr = null;

		skipNewlines();

		// Parse except clauses
		while (check(TExcept)) {
			advance();
			var exceptType:Expr = null;
			var varName = "";

			// Parse exception type
			if (!check(TColon) && !check(TAs)) {
				exceptType = parseExprNoAssign();
			}

			// Parse 'as' variable
			if (match([TAs])) {
				varName = consumeIdent("Expected variable name after 'as'");
			}

			consume(TColon, "Expected ':' after except");
			consumeNewline();
			var body = parseBlock();
			excepts.push({type: exceptType, varName: varName, body: body});
			skipNewlines();
		}

		// Parse else clause (after excepts)
		var elseBlock:Expr = null;
		if (check(TElse)) {
			advance();
			consume(TColon, "Expected ':' after else");
			consumeNewline();
			elseBlock = parseBlock();
			skipNewlines();
		}

		// Parse finally clause
		if (check(TFinally)) {
			advance();
			consume(TColon, "Expected ':' after finally");
			consumeNewline();
			finallyBlock = parseBlock();
		}

		// Build the try statement
		var catchBlock:Expr = null;
		if (excepts.length > 0) {
			// Chain all except blocks
			for (i in 0...excepts.length) {
				var exc = excepts[i];
				var next = if (i < excepts.length - 1) excepts[i + 1].body else (elseBlock != null ? elseBlock : EConst(CInt(0)));
				if (i == 0) {
					catchBlock = exc.body;
				}
			}
			// Just use the first except for now
			catchBlock = excepts[0].body;
		} else if (elseBlock != null) {
			catchBlock = elseBlock;
		} else {
			catchBlock = EConst(CInt(0));
		}

		return ETry(tryBlock, excepts.length > 0 ? excepts[0].varName : "", null, catchBlock, finallyBlock);
	}

	private function parseRaise():Expr {
		consume(TRaise, "Expected 'raise'");
		
		var exception:Expr = null;
		if (!check(TNewline) && !isAtEnd()) {
			exception = parseExpression();
		}
		
		consumeNewline();
		return EThrow(exception != null ? exception : EIdent("Exception"));
	}

	private function parseWith():Expr {
		consume(TWith, "Expected 'with'");
		
		// Parse with item(s)
		var items:Array<{expr:Expr, varName:String}> = [];
		
		while (true) {
			var expr = parseExprNoAssign();
			var varName = "";
			
			if (match([TAs])) {
				varName = consumeIdent("Expected variable name after 'as'");
			}
			
			items.push({expr: expr, varName: varName});
			skipNewlines();
			
			if (!match([TComma])) {
				break;
			}
			skipNewlines();
		}
		
		consume(TColon, "Expected ':' after with");
		consumeNewline();
		var body = parseBlock();
		
		// Handle single with item for now
		var first = items[0];
		return EWith(first.expr, if (first.varName != "") EIdent(first.varName) else EConst(CInt(0)), body);
	}

	private function parseMatch():Expr {
		consume(TMatch, "Expected 'match'");
		var subject = parseExpression();
		consume(TColon, "Expected ':' after match");
		consumeNewline();
		
		var cases:Array<{pattern:Expr, guard:Null<Expr>, body:Expr}> = [];
		
		consume(TIndent, "Expected indented block");
		
		while (check(TCase)) {
			advance();
			
			var pattern:Expr = null;
			var guard:Null<Expr> = null;
			
			// Parse pattern
			if (!check(TColon) && !check(TIf)) {
				pattern = parseExprNoAssign();
			}
			
			// Parse guard (if present)
			if (match([TIf])) {
				guard = parseExpression();
			}
			
			consume(TColon, "Expected ':' after case pattern");
			consumeNewline();
			var body = parseBlock();
			
			cases.push({pattern: pattern, guard: guard, body: body});
			skipNewlines();
		}
		
		consume(TDedent, "Expected dedent after match");
		
		return EMatch(subject, cases);
	}

	private function parseAsync():Expr {
		consume(TAsync, "Expected 'async'");
		
		if (check(TDef)) {
			// Async function
			advance();
			var func = parseFunction();
			return EAsync(func);
		} else if (check(TFor)) {
			// Async for loop
			advance();
			var varName = consumeIdent("Expected variable name");
			consume(TIn, "Expected 'in' in async for");
			var iter = parseExpression();
			consume(TColon, "Expected ':' after async for");
			consumeNewline();
			var body = parseBlock();
			
			// Note: Full async for needs special handling
			return EFor(varName, iter, body);
		} else {
			// Just async as keyword before expression
			var expr = parseExpression();
			return EAsync(expr);
		}
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

	private function parseExprNoAssign():Expr {
		return parseOrExpression();
	}

	private function parseAssignment():Expr {
		var savedPos = pos;

		// 1) Parse assignment targets (single or tuple)
		var targets:Array<Expr> = [];
		var isTuple = false;

		// Parenthesized tuple: (a, b)
		if (match([TLparen])) {
			// Allow newlines after '('
			skipNewlines();
			if (!check(TRparen)) {
				// Allow newlines before first target
				skipNewlines();
				do {
					// Allow newlines before each target
					skipNewlines();
					targets.push(parseOrExpression());
					// Allow newlines after each target (before potential comma or closing paren)
					skipNewlines();
				} while (match([TComma])); // This consumes the comma if present
					// Allow newlines after the last target (before closing paren)
				skipNewlines();
			} else {
				// () - Empty tuple
				consume(TRparen, "Expected ')'");
				return ETuple([]);
			}
			consume(TRparen, "Expected ')'");
			isTuple = targets.length > 1;
		}

		// Non-parenthesized: a, b
		if (!isTuple && targets.length == 0) {
			var first = parseOrExpression();
			targets.push(first);

			// Allow newlines after the first target (before potential comma)
			skipNewlines();
			if (match([TComma])) { // This consumes the comma if present
				// Allow newlines after the comma (before the next target)
				skipNewlines();
				// Allow newlines before each subsequent target
				skipNewlines();
				do {
					// Allow newlines before each target
					skipNewlines();
					targets.push(parseOrExpression());
					// Allow newlines after each target (before potential comma or newline/assign)
					skipNewlines();
				} while (match([TComma]) && !check(TNewline) && !check(TAssign)); // This consumes the comma if present and not followed by newline/assign
				isTuple = true;
			}
		}

		// 2) Walrus operator (:=)
		if (!isTuple && match([TWalrus])) {
			// Use parseExprNoAssign to avoid parsing (x := 5) as a tuple
			var value = parseExprNoAssign();
			return switch (Tools.expr(targets[0])) {
				case EIdent(name):
					EVar(name, null, value);
				default:
					error("Invalid walrus assignment target");
					EConst(CInt(0));
			};
		}

		// 3) Assignment (=)
		if (match([TAssign])) {
			var value:Expr;

			// For tuple unpacking, parse a tuple on the right side too
			if (isTuple) {
				var values:Array<Expr> = [];
				skipNewlines();
				do {
					values.push(parseOrExpression());
					skipNewlines();
				} while (match([TComma]));
				value = values.length == 1 ? values[0] : ETuple(values);
			} else {
				// Use parseExprNoAssign to avoid parsing (x := 5) as a tuple
				value = parseExprNoAssign();
			}

			// Tuple unpacking
			if (isTuple) {
			// For tuple unpacking, create EUnpack expression so the interpreter
			// can handle runtime tuple extraction
			var targetNames = [];
			for (t in targets) {
				switch (Tools.expr(t)) {
					case EIdent(name): targetNames.push(name);
					default:
						error("Invalid assignment target");
				}
			}
			return EUnpack(targetNames, value);
			}

			// Single assignment
			return switch (Tools.expr(targets[0])) {
				case EIdent(name):
					EVar(name, null, value);
				case EField(_, _), EArray(_, _):
					EBinop("=", targets[0], value);
				default:
					error("Invalid assignment target");
					EConst(CInt(0));
			};
		}

		// 4) Augmented assignment (only single target allowed)
		if (!isTuple) {
			if (match([TPlusAssign]))
				return EBinop("+=", targets[0], parseAssignment());
			if (match([TMinusAssign]))
				return EBinop("-=", targets[0], parseAssignment());
			if (match([TStarAssign]))
				return EBinop("*=", targets[0], parseAssignment());
			if (match([TSlashAssign]))
				return EBinop("/=", targets[0], parseAssignment());
		}

		if (match([TPercentAssign])) {
			return EBinop("%=", targets[0], parseAssignment());
		}

		// 5) Not an assignment at all → restore and parse expression
		pos = savedPos;
		return parseOrExpression();
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
			} else if (match([TIs])) {
				var right = parseBitwiseOr();
				expr = EBinop("is", expr, right);
			} else if (match([TNotIn])) {
				var right = parseBitwiseOr();
				expr = EBinop("not in", expr, right);
			} else if (check(TIn)) {
				// "in" operator
				advance();
				var right = parseBitwiseOr();
				expr = EBinop("in", expr, right);
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

	private function parseArg():Expr {
		// Check if it's a keyword argument (name=value)
		var savedPos = pos;
		
		// Only check for keyword if the next token is an identifier
		var tok = peek();
		switch (tok.type) {
			case TIdent(_):
				var name = consumeIdent("Expected argument");
				if (check(TAssign)) {
					// It's a keyword argument
					advance();
					var value = parseExprNoAssign();
					return EBinop("=", EIdent(name), value);
				}
				// Not a keyword argument - restore position
				pos = savedPos;
			default:
				// Not an identifier, parse normally
		}
		
		return parseExprNoAssign();
	}

	private function parsePostfix():Expr {
		var expr = parsePrimary();

		while (true) {
			if (match([TLparen])) {
				// Allow newlines after '('
				skipNewlines();
				var args:Array<Expr> = [];
				if (!check(TRparen)) {
					// Allow newlines before the first argument
					skipNewlines();
					args.push(parseArg());
					// Allow newlines after the first argument (before potential comma)
					skipNewlines();
					// Handle comma-separated arguments and trailing comma
					while (match([TComma])) {
						// Allow newlines after the comma (before the next argument)
						skipNewlines();
						// Check if next token is closing paren (handles trailing comma)
						if (check(TRparen))
							break;
						// Allow newlines before the next argument
						skipNewlines();
						args.push(parseArg());
						// Allow newlines after each argument (before potential comma or closing paren)
						skipNewlines();
					}
					// Allow newlines before closing paren
					skipNewlines();
				}
				consume(TRparen, "Expected ')' after arguments");
				expr = ECall(expr, args);
			} else if (match([TLbracket])) {
				// Allow newlines after '['
				skipNewlines();
				// Array/map access or slice
				var start:Expr = null;
				var end:Expr = null;
				var step:Expr = null;

				if (!check(TRbracket)) {
					// Check if it's a slice (has colon)
					if (check(TColon)) {
						// Slice: [:] or [::step] or [:end:step]
						advance();
						if (check(TColon)) {
							// [::step] - no start, no end, just step
							advance();
							if (!check(TRbracket)) {
								step = parseExpression();
							}
						} else if (!check(TRbracket)) {
							// [:end] or [:end:step]
							end = parseExpression();
							if (match([TColon])) {
								step = parseExpression();
							}
						}
						// Allow newlines before ']'
						skipNewlines();
						consume(TRbracket, "Expected ']' after slice");
						expr = ESlice(expr, start, end, step);
					} else {
						// Regular index or slice
						var first = parseExpression();
						if (match([TColon])) {
							// Slice: [start:end:step]
							start = first;
							if (!check(TRbracket)) {
								end = parseExpression();
								if (match([TColon])) {
									step = parseExpression();
								}
							}
							// Allow newlines before ']'
							skipNewlines();
							consume(TRbracket, "Expected ']' after slice");
							expr = ESlice(expr, start, end, step);
						} else {
							// Regular index
							// Allow newlines before ']'
							skipNewlines();
							consume(TRbracket, "Expected ']' after index");
							expr = EArray(expr, first);
						}
					}
				} else {
					// Empty slice []
					consume(TRbracket, "Expected ']'");
					expr = ESlice(expr, null, null, null);
				}
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
				// For now, treat f-strings as regular strings
				// Full f-string support requires parsing {expressions}
				if (value.indexOf("f") == 0 || value.indexOf("F") == 0) {
					// Remove 'f' prefix and treat as regular string
					var strVal = value.substr(1);
					return EConst(CString(strVal));
				}
				return EConst(CString(value));

			case TBytes(data):
				advance();
				return EBytes(data);

			case TEllipsis:
				advance();
				return EEllipsis;

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
				// Allow newlines after '('
				skipNewlines();

				// Check for empty tuple immediately after '(' and newlines
				if (check(TRparen)) {
					advance();
					return ETuple([]);
				}

				var first = parseExpression();
				// Allow newlines after the first expression (before potential comma or closing paren)
				skipNewlines();

				// Check for generator expression BEFORE checking for closing paren
				if (check(TFor)) {
					// Generator expression: (expr for var in iter if cond)
					advance(); // NOW consume the 'for'
					var loops:Array<{varname:String, iter:Expr, ?cond:Expr}> = [];

					while (true) {
						var varName = consumeIdent("Expected variable name");
						consume(TIn, "Expected 'in' in generator");
						var iter = parseExpression();
						var cond:Expr = null;
						if (match([TIf])) {
							cond = parseExpression();
						}
						loops.push({varname: varName, iter: iter, cond: cond});

						skipNewlines();
						if (!check(TFor)) {
							break;
						}
						advance(); // consume next 'for'
					}

					skipNewlines();
					consume(TRparen, "Expected ')' after generator");
					return EGenerator(first, loops);
				}

				// Check for tuple
				if (match([TComma])) { // This consumes the comma if present
					// Allow newlines after the comma (before the next element)
					skipNewlines();
					// Allow newlines before the second element (if it exists)
					skipNewlines();
					// Tuple: (a,) or (a, b, ...)
					var elements:Array<Expr> = [first];
					do {
						// Allow newlines before each subsequent element
						skipNewlines();
						elements.push(parseExpression());
						// Allow newlines after each element (before potential comma or closing paren)
						skipNewlines();
					} while (match([TComma])); // This consumes the comma if present
						// Allow newlines after the last element (before closing paren)
					skipNewlines();
					consume(TRparen, "Expected ')' after tuple");
					return ETuple(elements);
				}

				// Single parenthesized expression
				// Allow newlines before ')'
				skipNewlines();
				consume(TRparen, "Expected ')' after expression");
				return EParent(first);

			case TLbracket:
				advance();
				// Allow newlines after '['
				skipNewlines();

				// Check for empty list immediately after '[' and newlines
				if (check(TRbracket)) {
					advance();
					return EArrayDecl([]);
				}

				var first = parseExpression();
				// Allow newlines after the first element (before potential comma, 'for', or closing bracket)
				skipNewlines();

				if (match([TFor])) { // This consumes the 'for' if present
					// List comprehension: [expr for var in iter if cond] or nested loops
					var loops:Array<{varname:String, iter:Expr, ?cond:Expr}> = [];

					// Parse all for loops
					// Allow newlines before the first 'for' variable
					skipNewlines();
					while (true) {
						var varName = consumeIdent("Expected variable name");
						consume(TIn, "Expected 'in' in comprehension");
						var iter = parseExpression();
						var cond:Expr = null;
						if (match([TIf])) { // This consumes the 'if' if present
							cond = parseExpression();
						}
						loops.push({varname: varName, iter: iter, cond: cond});

						// Check if there's another for loop
						// Allow newlines after the current 'for' clause (before potential next 'for')
						skipNewlines();
						if (!match([TFor])) { // This consumes the 'for' if present
							break;
						}
					}

					// Allow newlines after the last 'for' clause (before closing bracket)
					skipNewlines();
					consume(TRbracket, "Expected ']' after comprehension");
					return EComprehension(first, loops, false, null);
				} else {
					// Regular list
					var elements:Array<Expr> = [first];
					// Allow newlines after the first element (before potential comma)
					skipNewlines();
					while (match([TComma])) { // This consumes the comma if present
						// Allow newlines after the comma (before the next element)
						skipNewlines();
						// Allow newlines before the next element (if it exists)
						skipNewlines();
						// Check if the next token is the closing bracket (handles trailing comma)
						if (check(TRbracket))
							break;
						elements.push(parseExpression());
						// Allow newlines after each element (before potential comma or closing bracket)
						skipNewlines();
					}
					// Allow newlines after the last element (before closing bracket)
					skipNewlines();
					consume(TRbracket, "Expected ']' after list");
					return EArrayDecl(elements);
				}

			case TLbrace:
				advance();
				// Allow newlines after '{'
				skipNewlines();
				
				// Check if it's a set or dict by looking ahead
				var isDict = false;
				var setElements:Array<Expr> = [];
				var dictFields:Array<{name:String, e:Expr}> = [];
				
				if (!check(TRbrace)) {
					// Peek at first element to determine if dict or set
					var firstPos = pos;
					skipNewlines();
					
					// Check for set literal (no colon)
					// Parse first expression
					var firstExpr = parseExpression();
					skipNewlines();
					
					if (check(TColon)) {
						// It's a dictionary
						isDict = true;
						// Put back the first key-value
						var key = switch (Tools.expr(firstExpr)) {
							case EConst(CString(s)): s;
							case EIdent(s): s;
							default: "";
						};
						consume(TColon, "Expected ':' after key");
						skipNewlines();
						var value = parseExpression();
						skipNewlines();
						dictFields.push({name: key, e: value});
						
						while (match([TComma])) {
							skipNewlines();
							if (check(TRbrace)) break;
							
							// Parse key - can be identifier or string
							var keyExpr = parseExpression();
							var k = switch (Tools.expr(keyExpr)) {
								case EConst(CString(s)): s;
								case EIdent(s): s;
								default: "";
							};
							consume(TColon, "Expected ':' after key");
							skipNewlines();
							var v = parseExpression();
							skipNewlines();
							dictFields.push({name: k, e: v});
						}
					} else {
						// It's a set
						isDict = false;
						setElements = [firstExpr];
						
						while (match([TComma])) {
							skipNewlines();
							if (check(TRbrace)) break;
							setElements.push(parseExpression());
							skipNewlines();
						}
					}
				}
				
				skipNewlines();
				consume(TRbrace, "Expected '}'");
				
				if (isDict) {
					return EObject(dictFields);
				} else {
					return ESet(setElements);
				}

			case TLambda:
				advance();
				var args:Array<Argument> = [];
				if (!check(TColon)) {
					// Allow newlines before the first argument
					skipNewlines();
					do {
						// Allow newlines before each argument
						skipNewlines();
						var argName = consumeIdent("Expected parameter name");
						args.push({
							name: argName,
							t: null,
							opt: false,
							value: null
						});
						// Allow newlines after each argument (before potential comma or colon)
						skipNewlines();
					} while (match([TComma])); // This consumes the comma if present
						// Allow newlines after the last argument (before colon)
					skipNewlines();
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

	private function checkAhead(type:TokenType):Bool {
		if (pos + 1 >= tokens.length)
			return false;
		return compareTokenTypes(tokens[pos + 1].type, type);
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

	private function isTypeIdent(token:Token):Bool {
		return switch (token.type) {
			case TIdent(_): true;
			case TInt(_), TFloat(_), TString(_): true;
			default: false;
		}
	}

	private function parseTypeHint():CType {
		skipNewlines();
		
		if (isTypeIdent(peek())) {
			var name = consumeIdent("Expected type name");
			skipNewlines();
			
			if (check(TLbracket)) {
				advance();
				skipNewlines();
				var params:Array<CType> = [];
				
				if (!check(TRbracket)) {
					params.push(parseTypeHint());
					skipNewlines();
					while (match([TComma])) {
						skipNewlines();
						if (check(TRbracket))
							break;
						params.push(parseTypeHint());
						skipNewlines();
					}
				}
				skipNewlines();
				consume(TRbracket, "Expected ']' after type parameters");
				return CTPath([name], params);
			}
			
			return CTPath([name], null);
		}
		
		if (check(TLparen)) {
			advance();
			skipNewlines();
			var args:Array<CType> = [];
			
			if (!check(TRparen)) {
				args.push(parseTypeHint());
				skipNewlines();
				while (match([TComma])) {
					skipNewlines();
					if (check(TRparen))
						break;
					args.push(parseTypeHint());
					skipNewlines();
				}
			}
			skipNewlines();
			consume(TRparen, "Expected ')' in type");
			skipNewlines();
			consume(TArrow, "Expected '->' after callable args");
			skipNewlines();
			var ret = parseTypeHint();
			return CTFun(args, ret);
		}
		
		return CTPath(["Unknown"], null);
	}

	private function consumeNewline() {
		skipNewlines();
	}

	private function skipNewlines() {
		while (check(TNewline)) {
			advance();
		}
	}

	private function parseImport():Expr {
		consume(TImport, "Expected 'import'");
		var path:Array<String> = [];
		path.push(consumeIdent("Expected module name"));

		while (match([TDot])) {
			path.push(consumeIdent("Expected module name after '.'"));
		}

		var alias:String = null;
		if (match([TAs])) {
			alias = consumeIdent("Expected alias after 'as'");
		}

		consumeNewline();
		return EImport(path, alias);
	}

	private function parseImportFrom():Expr {
		consume(TFrom, "Expected 'from'");
		var path:Array<String> = [];
		path.push(consumeIdent("Expected module name"));

		while (match([TDot])) {
			path.push(consumeIdent("Expected module name after '.'"));
		}

		consume(TImport, "Expected 'import' after module path");

		var items:Array<String> = [];
		if (match([TStar])) {
			items.push("*");
		} else {
			// Allow newlines before the first item
			skipNewlines();
			do {
				// Allow newlines before each item
				skipNewlines();
				items.push(consumeIdent("Expected identifier to import"));
				// Allow newlines after each item (before potential comma or newline)
				skipNewlines();
			} while (match([TComma])); // This consumes the comma if present
				// Allow newlines after the last item (before newline)
			skipNewlines();
		}

		var alias:String = null;
		if (items.length == 1 && match([TAs])) {
			alias = consumeIdent("Expected alias after 'as'");
		}

		consumeNewline();
		return EImportFrom(path, items, alias);
	}

	private function parseDel():Expr {
		consume(TDel, "Expected 'del'");
		var target = parseExpression();
		consumeNewline();
		return EDel(target);
	}

	private function parseAssert():Expr {
		consume(TAssert, "Expected 'assert'");
		var cond = parseExpression();
		var msg:Expr = null;
		if (match([TComma])) {
			msg = parseExpression();
		}
		consumeNewline();
		return EAssert(cond, msg);
	}

	private function parseClass():Expr {
		consume(TClass, "Expected 'class'");
		var name = consumeIdent("Expected class name");

		// Skip inheritance for now
		var baseClasses:Array<Expr> = [];
		if (match([TLparen])) {
			// Allow newlines after '('
			skipNewlines();
			if (!check(TRparen)) {
				// Allow newlines before the first base class
				skipNewlines();
				do {
					// Allow newlines before each base class
					skipNewlines();
					baseClasses.push(parseExpression());
					// Allow newlines after each base class (before potential comma or closing paren)
					skipNewlines();
				} while (match([TComma])); // This consumes the comma if present
					// Allow newlines after the last base class (before closing paren)
				skipNewlines();
			}
			consume(TRparen, "Expected ')' after base classes");
		}

		consume(TColon, "Expected ':' after class name");
		consumeNewline();

		var body = parseBlock();

		// Return a proper class definition expression
		return EClass(name, baseClasses, body);
	}

	private function error(message:String):Expr {
		var token = peek();
		throw new ParseException(new SyntaxError(message), token.line, token.column);
		return null;
	}
}
