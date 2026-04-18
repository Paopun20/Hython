package paopao.hython;

import paopao.hython.Lexer;
import paopao.hython.Ast;

/*
 * Parser for the Hython language. This takes a stream of tokens from the lexer and produces an abstract syntax tree (AST) representing the program structure.
 * The parser implements a recursive descent parsing strategy, with separate methods for each level of operator precedence and statement type.
 * It also handles indentation-based block structure, converting indents and dedents into nested AST nodes
 * representing code blocks.
 * The main entry point is the `parse()` method, which returns an `Expr` representing the entire program. The parser maintains a mapping of variable names to internal IDs for use in the AST.
 */
class Parser {
	private var lexer:Lexer;
	private var current:Token;

	public function new(source:String) {
		lexer = new Lexer(source);
		current = lexer.nextToken();
	}

	private function advance():Token {
		var prev = current;
		current = lexer.nextToken();
		return prev;
	}

	private function peek():Token {
		return current;
	}

	private function expect(token:Token):Void {
		if (!tokenMatches(current, token)) {
			throw "Expected " + tokenToString(token) + " but got " + tokenToString(current);
		}
		advance();
	}

	// Skip over any TNewline tokens (used between statements)
	private function skipNewlines():Void {
		while (current == TNewline)
			advance();
	}

	private function tokenMatches(a:Token, b:Token):Bool {
		return Type.enumEq(a, b);
	}

	private function tokenToString(token:Token):String {
		return switch token {
			case TIdent(s): "identifier '" + s + "'"; // include the identifier name for better error messages
			case TInt(n): "int " + n; // include the integer value for better error messages
			case TFloat(f): "float " + f; // include the float value for better error messages
			case TString(s): "string '" + s + "'"; // include the string value for better error messages
			case TPlus: "+";
			case TMinus: "-"; 
			case TMul: "*";
			case TDiv: "/";
			case TEqual: "=";
			case TPlusEqual: "+=";
			case TInc: "++";
			case TDec: "--";
			case TEqualEqual: "==";
			case TNotEqual: "!=";
			case TLess: "<";
			case TGreater: ">";
			case TLessEqual: "<=";
			case TGreaterEqual: ">=";
			case TAnd: "&&";
			case TOr: "||";
			case TNot: "!";
			case TColon: ":";
			case TComma: ",";
			case TDot: ".";
			case TLParen: "(";
			case TRParen: ")";
			case TLBracket: "[";
			case TRBracket: "]";
			case TIndent: "INDENT";
			case TDedent: "DEDENT";
			case TNewline: "NEWLINE";
			case TIf: "if";
			case TElse: "else";
			case TWhile: "while";
			case TFor: "for";
			case TIn: "in";
			case TDef: "def";
			case TReturn: "return";
			case TImport: "import";
			case TFrom: "from";
			case TAs: "as";
			case TEOF: "EOF";
		};
	}

	// Top-level
	public function parse():Expr {
		var exprs = [];
		skipNewlines();
		while (current != TEOF) {
			exprs.push(parseStatement());
			skipNewlines();
		}
		return new Expr(EBlock(exprs), 1, 1);
	}

	// Statements
	private function parseStatement():Expr {
		var stmt = switch current {
			case TIf: parseIf();
			case TWhile: parseWhile();
			case TFor: parseFor();
			case TDef: parseFunction();
			case TReturn: parseReturn();
			case TImport: parseImport();
			case TFrom: parseImportFrom();
			default: parseExpression();
		};
		// Consume the trailing newline after a statement (if present)
		skipNewlines();
		return stmt;
	}

	private function parseIf():Expr {
		advance(); // consume 'if'
		var cond = parseExpression();
		expect(TColon);
		var thenExpr = parseIndentedBlock();
		var elseExpr:Expr;

		skipNewlines();

		if (current == TElse) {
			advance(); // consume 'else'
			expect(TColon);
			elseExpr = parseIndentedBlock();
		} else if (current == TIf) {
			// 'elif' was tokenised as TIf — recurse
			elseExpr = parseIf();
		} else {
			elseExpr = new Expr(EConstNone, 1, 1);
		}

		return new Expr(EIf(cond, thenExpr, elseExpr), 1, 1);
	}

	private function parseWhile():Expr {
		advance(); // consume 'while'
		var cond = parseExpression();
		expect(TColon);
		var body = parseIndentedBlock();
		return new Expr(EWhile(cond, body), 1, 1);
	}

	private function parseFor():Expr {
		advance(); // consume 'for'
		var varName = switch current {
			case TIdent(name):
				advance();
				name;
			default: throw "Expected variable name in for loop";
		};

		expect(TIn);
		var iterable = parseExpression();
		expect(TColon);
		var body = parseIndentedBlock();

		// TODO: proper for-in support; currently lowered to while
		return new Expr(EWhile(iterable, body), 1, 1);
	}

	private function parseFunction():Expr {
		advance(); // consume 'def'
		var funcName = switch current {
			case TIdent(name):
				advance();
				name;
			default: throw "Expected function name";
		};

		expect(TLParen);
		var args = [];

		while (current != TRParen) {
			if (current == TComma)
				advance();
			if (current != TRParen) {
				switch current {
					case TIdent(name):
						advance();
						args.push(new Argument(VArg(name, TAny, null), false, null));
					default:
						throw "Expected identifier in function arguments";
				}
			}
		}

		expect(TRParen);
		expect(TColon);
		var body = parseIndentedBlock();
		var funcValue = new Expr(EFunction(args, body), 1, 1);
		return new Expr(EAssign(TVar(VLocal(funcName, TAny, null)), Assign, funcValue), 1, 1);
	}

	private function parseReturn():Expr {
		advance(); // consume 'return'
		// Stop at newline, dedent, or EOF — the return value is on the same line
		var expr = if (current == TEOF || current == TNewline || current == TDedent) {
			new Expr(EConstNone, 1, 1);
		} else {
			parseExpression();
		};
		return new Expr(EReturn(expr), 1, 1);
	}

	private function parseImport():Expr {
		advance(); // consume 'import'
		var module = switch current {
			case TIdent(name):
				advance();
				name;
			default: throw "Expected module name";
		};

        var asName:VariableType = VLocal(module, TAny, null);

		return new Expr(EImport(module, asName), 1, 1);
	}

	private function parseImportFrom():Expr {
		advance(); // consume 'from'
		var module = switch current {
			case TIdent(name):
				advance();
				name;
			default: throw "Expected module name";
		};

		expect(TImport);
		var items = [];

		// Stop at newline, dedent, or EOF
		while (current != TEOF && current != TNewline && current != TDedent) {
			switch current {
				case TIdent(name):
					advance();
					var asName = VLocal(name, TAny, null);
					if (current == TAs) {
						advance();
						switch current {
							case TIdent(_):
								advance();
								asName = VLocal(name, TAny, null);
							default: throw "Expected identifier after 'as'";
						}
					}
					items.push(new ImportItem(name, asName));
					if (current == TComma)
						advance();
				default:
					break;
			}
		}

		return new Expr(EImportFrom(module, items), 1, 1);
	}

	private function parseIndentedBlock():Expr {
		expect(TNewline); // consume the newline after the colon
		expect(TIndent); // consume the INDENT

		var exprs = [];
		while (current != TDedent && current != TEOF) {
			exprs.push(parseStatement());
		}

		if (current == TDedent)
			advance(); // consume the DEDENT

		return switch exprs.length {
			case 0: new Expr(EConstNone, 1, 1);
			case 1: exprs[0];
			default: new Expr(EBlock(exprs), 1, 1);
		};
	}

	// Expressions - operator precedence parsing
	private function parseExpression():Expr {
		return parseAssignment();
	}

	private function parseAssignment():Expr {
		var expr = parseLogicalOr();

		if (current == TEqual || current == TPlusEqual) {
			var op = current;
			advance();
			var right = parseExpression();

			var assignOp = switch op {
				case TPlusEqual: AddAssign;
				default: Assign;
			};

			var target = exprToAssignTarget(expr);
			return new Expr(EAssign(target, assignOp, right), 1, 1);
		}

		return expr;
	}

	private function parseLogicalOr():Expr {
		var expr = parseLogicalAnd();
		while (current == TOr) {
			advance();
			var right = parseLogicalAnd();
			expr = new Expr(EBinop(OR, expr, right), 1, 1);
		}
		return expr;
	}

	private function parseLogicalAnd():Expr {
		var expr = parseEquality();
		while (current == TAnd) {
			advance();
			var right = parseEquality();
			expr = new Expr(EBinop(AND, expr, right), 1, 1);
		}
		return expr;
	}

	private function parseEquality():Expr {
		var expr = parseComparison();
		while (current == TEqualEqual || current == TNotEqual) {
			var op = current;
			advance();
			var right = parseComparison();
			var binop = switch op {
				case TNotEqual: NEQ;
				default: EQ;
			};
			expr = new Expr(EBinop(binop, expr, right), 1, 1);
		}
		return expr;
	}

	private function parseComparison():Expr {
		var expr = parseAddition();
		while (current == TLess || current == TGreater || current == TLessEqual || current == TGreaterEqual) {
			var op = current;
			advance();
			var right = parseAddition();
			var binop = switch op {
				case TGreater: GT;
				case TLessEqual: LTE;
				case TGreaterEqual: GTE;
				default: LT;
			};
			expr = new Expr(EBinop(binop, expr, right), 1, 1);
		}
		return expr;
	}

	private function parseAddition():Expr {
		var expr = parseMultiplication();
		while (current == TPlus || current == TMinus) {
			var op = current;
			advance();
			var right = parseMultiplication();
			var binop = switch op {
				case TMinus: SUB;
				default: ADD;
			};
			expr = new Expr(EBinop(binop, expr, right), 1, 1);
		}
		return expr;
	}

	private function parseMultiplication():Expr {
		var expr = parseUnary();
		while (current == TMul || current == TDiv) {
			var op = current;
			advance();
			var right = parseUnary();
			var binop = switch op {
				case TDiv: DIV;
				default: MUL;
			};
			expr = new Expr(EBinop(binop, expr, right), 1, 1);
		}
		return expr;
	}

	private function parseUnary():Expr {
		switch current {
			case TMinus:
				advance();
				return new Expr(EUnop(NEG, parseUnary()), 1, 1);
			case TNot:
				advance();
				return new Expr(EUnop(NOT, parseUnary()), 1, 1);
			case TInc:
				advance();
				return new Expr(EUnop(INC, parsePostfix()), 1, 1);
			case TDec:
				advance();
				return new Expr(EUnop(DEC, parsePostfix()), 1, 1);
			default:
				return parsePostfix();
		}
	}

	private function parsePostfix():Expr {
		var expr = parsePrimary();

		while (true) {
			switch current {
				case TDot:
					advance();
					switch current {
						case TIdent(name):
							advance();
							expr = new Expr(EField(expr, name), 1, 1);
						default:
							throw "Expected identifier after dot";
					}
				case TLBracket:
					advance();
					var index = parseExpression();
					expect(TRBracket);
					expr = new Expr(EIndex(expr, index), 1, 1);
				case TLParen:
					advance();
					var args = [];
					while (current != TRParen) {
						if (current == TComma)
							advance();
						if (current != TRParen)
							args.push(parseExpression());
					}
					expect(TRParen);
					expr = new Expr(ECall(expr, args), 1, 1);
				default:
					break;
			}
		}

		return expr;
	}

	private function parsePrimary():Expr {
		switch current {
			case TInt(n):
				advance();
				return new Expr(EConstInt(n), 1, 1);
			case TFloat(f):
				advance();
				return new Expr(EConstFloat(f), 1, 1);
			case TString(s):
				advance();
				return new Expr(EConstString(s), 1, 1);
			case TIdent(name):
				advance();
				return switch name {
					case "None": new Expr(EConstNone, 1, 1);
					case "True": new Expr(EConstBool(true), 1, 1);
					case "False": new Expr(EConstBool(false), 1, 1);
					default:
						new Expr(EVar(VLocal(name, TAny, null)), 1, 1);
				};
			case TLParen:
				advance();
				var expr = parseExpression();
				expect(TRParen);
				return expr;
			case TLBracket:
				advance();
				var elements = [];
				while (current != TRBracket) {
					if (current == TComma)
						advance();
					if (current != TRBracket)
						elements.push(parseExpression());
				}
				expect(TRBracket);
				return new Expr(EConstNone, 1, 1); // TODO: list literals
			default:
				throw "Unexpected token: " + tokenToString(current);
		}
	}

	// Helpers - used by both the parser and tests
	private function exprToAssignTarget(expr:Expr):AssignTarget {
		return switch expr.expr {
			case EVar(v): TVar(v);
			case EField(obj, name): TField(obj, name);
			case EIndex(obj, idx): TIndex(obj, idx);
			default: throw "Invalid assignment target";
		};
	}
}
