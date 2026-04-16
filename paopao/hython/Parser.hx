package paopao.hython;

import paopao.hython.Lexer;
import paopao.hython.Ast;

/**
 * Parser for the Hython language. This takes a list of tokens from the lexer and produces an abstract syntax tree (AST) that represents the structure of the code. The AST is then used by the interpreter to execute the code.
 * 
 */
class Parser {
    private var lexer:Lexer;
    private var current:Token;
    private var varCounter:Int = 0;
    private var varMap:Map<String, Int> = new Map();

    public function new(source:String) {
        lexer = new Lexer(source);
        current = lexer.nextToken();
    }

    private function getVarId(name:String):Int {
        if (!varMap.exists(name)) {
            varMap.set(name, varCounter++);
        }
        return varMap.get(name);
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

    private function tokenMatches(a:Token, b:Token):Bool {
        // Use type equality for simple comparison
        return Type.enumEq(a, b);
    }

    private function tokenToString(token:Token):String {
        return switch token {
            case TIdent(s): "identifier '" + s + "'";
            case TInt(n): "int " + n;
            case TFloat(f): "float " + f;
            case TString(s): "string '" + s + "'";
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

    public function parse():Expr {
        var exprs = [];
        while (current != TEOF) {
            exprs.push(parseStatement());
        }
        return new Expr(EBlock(exprs), 1, 1);
    }

    private function parseStatement():Expr {
        return switch current {
            case TIf: parseIf();
            case TWhile: parseWhile();
            case TFor: parseFor();
            case TDef: parseFunction();
            case TReturn: parseReturn();
            case TImport: parseImport();
            case TFrom: parseImportFrom();
            default: parseExpression();
        };
    }

    private function parseIf():Expr {
        advance(); // consume 'if'
        var cond = parseExpression();
        expect(TColon);
        var thenExpr = parseIndentedBlock();
        var elseExpr = null;
        
        if (current == TElse) {
            advance();
            expect(TColon);
            elseExpr = parseIndentedBlock();
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
            default:
                throw "Expected variable name in for loop";
        };
        
        expect(TIn);
        var iterable = parseExpression();
        expect(TColon);
        var body = parseIndentedBlock();
        
        // For now, convert to while loop (simplified)
        return new Expr(EWhile(iterable, body), 1, 1);
    }

    private function parseFunction():Expr {
        advance(); // consume 'def'
        var funcName = switch current {
            case TIdent(name):
                advance();
                name;
            default:
                throw "Expected function name";
        };
        
        expect(TLParen);
        var args = [];
        
        while (current != TRParen) {
            if (current == TComma) advance();
            if (current != TRParen) {
                switch current {
                    case TIdent(name):
                        advance();
                        var varId = getVarId(name); // Use getVarId to track argument variables
                        var arg = new Argument(VArg(varId), false, null);
                        args.push(arg);
                    default:
                        throw "Expected identifier in function arguments";
                }
            }
        }
        
        expect(TRParen);
        expect(TColon);
        var body = parseIndentedBlock();
        var funcValue = new Expr(EFunction(args, body), 1, 1);
        
        // Create an assignment: funcName = EFunction(...)
        var funcVarId = getVarId(funcName);
        return new Expr(EAssign(TVar(VLocal(funcVarId)), Assign, funcValue), 1, 1);
    }

    private function parseReturn():Expr {
        advance(); // consume 'return'
        var expr = if (current == TEOF || current == TElse) {
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
            default:
                throw "Expected module name";
        };
        
        var asName:VariableType = VLocal(varCounter++);
        if (current == TAs) {
            advance();
            switch current {
                case TIdent(name):
                    advance();
                    asName = VLocal(varCounter++);
                default:
                    throw "Expected identifier after 'as'";
            }
        }
        
        return new Expr(EImport(module, asName), 1, 1);
    }

    private function parseImportFrom():Expr {
        advance(); // consume 'from'
        var module = switch current {
            case TIdent(name):
                advance();
                name;
            default:
                throw "Expected module name";
        };
        
        expect(TImport); // 'import' keyword
        var items = [];
        
        while (current != TEOF && current != TElse) {
            switch current {
                case TIdent(name):
                    advance();
                    var asName = VLocal(varCounter++);
                    if (current == TAs) {
                        advance();
                        switch current {
                            case TIdent(_):
                                advance();
                                asName = VLocal(varCounter++);
                            default:
                                throw "Expected identifier after 'as'";
                        }
                    }
                    items.push(new ImportItem(name, asName));
                    if (current == TComma) {
                        advance();
                    }
                default:
                    break;
            }
        }
        
        return new Expr(EImportFrom(module, items), 1, 1);
    }

    private function parseIndentedBlock():Expr {
        var exprs = [];
        // Simple approach: collect statements until we hit EOF or dedent
        if (current != TEOF) {
            exprs.push(parseStatement());
        }
        
        return if (exprs.length == 1) exprs[0] else new Expr(EBlock(exprs), 1, 1);
    }

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
                case TEqual: Assign;
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
                case TEqualEqual: EQ;
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
                case TLess: LT;
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
                case TPlus: ADD;
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
                case TMul: MUL;
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
                var expr = parseUnary();
                return new Expr(EUnop(NEG, expr), 1, 1);
            case TNot:
                advance();
                var expr = parseUnary();
                return new Expr(EUnop(NOT, expr), 1, 1);
            case TInc:
                advance();
                var expr = parsePostfix();
                return new Expr(EUnop(INC, expr), 1, 1);
            case TDec:
                advance();
                var expr = parsePostfix();
                return new Expr(EUnop(DEC, expr), 1, 1);
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
                        if (current == TComma) advance();
                        if (current != TRParen) {
                            args.push(parseExpression());
                        }
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
                // Handle None, True, False
                if (name == "None") {
                    return new Expr(EConstNone, 1, 1);
                } else if (name == "True") {
                    return new Expr(EConstBool(true), 1, 1);
                } else if (name == "False") {
                    return new Expr(EConstBool(false), 1, 1);
                }
                var varId = getVarId(name);
                return new Expr(EVar(VLocal(varId)), 1, 1);
            case TLParen:
                advance();
                var expr = parseExpression();
                expect(TRParen);
                return expr;
            case TLBracket:
                advance();
                var elements = [];
                while (current != TRBracket) {
                    if (current == TComma) advance();
                    if (current != TRBracket) {
                        elements.push(parseExpression());
                    }
                }
                expect(TRBracket);
                // Return as array/list
                return new Expr(EConstNone, 1, 1); // TODO: handle list literals
            default:
                throw "Unexpected token: " + tokenToString(current);
        }
    }

    private function exprToAssignTarget(expr:Expr):AssignTarget {
        return switch expr.expr {
            case EVar(v): TVar(v);
            case EField(obj, name): TField(obj, name);
            case EIndex(obj, index): TIndex(obj, index);
            default:
                throw "Invalid assignment target";
        };
    }
}