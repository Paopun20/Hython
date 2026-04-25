package paopao.hython;

import paopao.hython.Ast;
import paopao.hython.Error;
import paopao.hython.Lexer;

class Parser {
	public var tokens:Array<Token>;
	public var pos:Int;

	public function new(tokens:Array<Token>) {
		this.tokens = tokens;
		this.pos = 0;
	}

	// Helpers zone functions for peeking, advancing, and character classification

	private function peek(offset:Int = 0):Token {
		var i = pos + offset;
		if (i >= tokens.length)
			return TEOF;
		return tokens[i];
	}

	private function advance():Token {
		var t = peek();
		pos++;
		return t;
	}

	private function match(t:Token):Bool {
		if (Type.enumEq(peek(), t)) {
			advance();
			return true;
		}
		return false;
	}

	private function expect(t:Token):Void {
		if (!match(t)) {
			throw new Error(SyntaxError("Expected " + t + " but got " + peek()), 0, 0);
		}
	}

	// Entry point for parsing. This will parse the entire token stream into an AST Module.

	public function parse():Module {
		var body:Array<Stmt> = [];

		while (!Type.enumEq(peek(), TEOF)) {
			if (match(TNewline))
				continue;
			body.push(parseStmt());
		}

		return new Module(body);
	}

	// Statements (Top-down recursive descent)

	private function parseStmt():Stmt {
		return switch (peek()) {
			case TIf: parseIf();
			case TWhile: parseWhile();
			case TDef: parseFunction();
			case TReturn: parseReturn();
			default: parseSimpleStmt();
		};
	}

	private function parseSimpleStmt():Stmt {
		var expr = parseExpr();

		if (match(TEqual)) {
			var value = parseExpr();
			return SAssign([expr], value);
		}

		return SExpr(expr);
	}

	private function parseReturn():Stmt {
		advance();
		if (Type.enumEq(peek(), TNewline)) {
			return SReturn(null);
		}
		return SReturn(parseExpr());
	}

	private function parseIf():Stmt {
		advance(); // if
		var test = parseExpr();
		expect(TColon);

		var body = parseBlock();
		var orelse:Array<Stmt> = [];

		if (match(TElse)) {
			expect(TColon);
			orelse = parseBlock();
		}

		return SIf(test, body, orelse);
	}

	private function parseWhile():Stmt {
		advance();
		var test = parseExpr();
		expect(TColon);

		var body = parseBlock();
		return SWhile(test, body, []);
	}

	private function parseFunction():Stmt {
		advance(); // def

		var name = switch (advance()) {
			case TIdent(id): id;
			default: throw new Error(SyntaxError("Expected function name"), 0, 0);
		};

		expect(TLParen);
		var args = parseArgs();
		expect(TRParen);
		expect(TColon);

		var body = parseBlock();

		return SFunctionDef(name, args, body, null, false);
	}

	private function parseArgs():Arguments {
		var list:Array<Arg> = [];

		while (!Type.enumEq(peek(), TRParen)) {
			var name = switch (advance()) {
				case TIdent(id): id;
				default: throw new Error(SyntaxError("Expected arg"), 0, 0);
			};

			list.push(new Arg(name, null));

			if (!match(TComma))
				break;
		}

		return new Arguments(list);
	}

	private function parseBlock():Array<Stmt> {
		expect(TNewline);
		expect(TIndent);

		var body:Array<Stmt> = [];

		while (!match(TDedent)) {
			if (match(TNewline))
				continue;
			body.push(parseStmt());
		}

		return body;
	}

	// Expression (Pratt Parser)

	private function parseExpr():Expr {
		return parseBinary(0);
	}

	private function getPrecedence(op:Token):Int {
		return switch (op) {
			case TPlus | TMinus: 10;
			case TMul | TDiv: 20;
			default: -1;
		};
	}

	private function parseBinary(minPrec:Int):Expr {
		var left = parsePrimary();

		while (true) {
			var op = peek();
			var prec = getPrecedence(op);

			if (prec < minPrec)
				break;

			advance();

			var right = parseBinary(prec + 1);

			left = EBinOp(left, mapOp(op), right);
		}

		return left;
	}

	private function mapOp(t:Token):BinOp {
		return switch (t) {
			case TPlus: BinOp.Add;
			case TMinus: BinOp.Sub;
			case TMul: BinOp.Mult;
			case TDiv: BinOp.Div;
			default:
				throw new Error(SyntaxError("Unknown operator"), 0, 0);
		};
	}

	private function parsePrimary():Expr {
		var expr:Expr = switch (advance()) {
			case TInt(v): EConstant(CInt(v));
			case TFloat(v): EConstant(CFloat(v));
			case TString(v): EConstant(CString(v));
			case TIdent(name): EName(name);

			case TLParen:
				var e = parseExpr();
				expect(TRParen);
				e;

			default:
				throw new Error(SyntaxError("Unexpected token"), 0, 0);
		};

		return parsePostfix(expr);
	}

	private function parsePostfix(expr:Expr):Expr {
		while (true) {
			switch (peek()) {
				case TLParen:
					advance();
					var args:Array<Expr> = [];

					while (!Type.enumEq(peek(), TRParen)) {
						args.push(parseExpr());
						if (!match(TComma))
							break;
					}

					expect(TRParen);
					expr = ECall(expr, args);

				case TDot:
					advance();
					var name = switch (advance()) {
						case TIdent(id): id;
						default: throw new Error(SyntaxError("Expected attribute"), 0, 0);
					};
					expr = EAttribute(expr, name);

				case TLBracket:
					advance();
					var index = parseExpr();
					expect(TRBracket);
					expr = ESubscript(expr, index);

				default:
					return expr;
			}
		}
	}
}
