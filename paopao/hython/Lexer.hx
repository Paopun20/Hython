package paopao.hython;

import paopao.hython.Ast;
import paopao.hython.Error;
import String as HxString;

enum TokenType {
    Identifier;
    Number;
    String;
    Keyword;
    Operator;
    Punctuation;
}

enum Token {
    TIdent(String: String);
    TInt(Int: Int);
    TFloat(Float: Float);
    TString(String: String);

    // operators
    TPlus;
    TMinus;
    TMul;
    TDiv;

    TPlusEqual; // +=
    TEqual;     // =
    TEqualEqual; // ==
    TNotEqual;  // !=

    TInc; // ++
    TDec; // --

    TLess;      // <
    TGreater;   // >
    TLessEqual; // <=
    TGreaterEqual; // >=

    TAnd;       // &&
    TOr;        // ||
    TNot;       // !

    // symbols
    TLParen;
    TRParen;
    TLBracket;
    TRBracket;
    TComma;
    TDot;
    TColon;      // :

    // keywords
    TIf;
    TElse;
    TWhile;
    TDef;
    TReturn;
    TImport;
    TFrom;
    TAs;
    TFor;
    TIn;

    TEOF;
}

class Lexer {
    public var source:String;
    public var tokens:Array<Token>;
    public var pos:Int;
    public var line:Int;
    public var col:Int;

    public function new(source:String) {
        this.source = source;
        this.tokens = [];
        this.pos = 0;
        this.line = 1;
        this.col = 1;
    }

    public function tokenize():Array<Token> {
        while (true) {
            var token = nextToken();
            tokens.push(token);
            if (token == TEOF) break;
        }
        return tokens;
    }

    private function peek(offset:Int = 0):String {
        var index = pos + offset;
        if (index >= source.length) return HxString.fromCharCode(0);
        return source.charAt(index);
    }

    private function advance():String {
        if (pos >= source.length) return HxString.fromCharCode(0);
        var ch = source.charAt(pos);
        pos++;
        if (ch == "\n") {
            line++;
            col = 1;
        } else {
            col++;
        }
        return ch;
    }

    private function skipWhitespace():Void {
        while (pos < source.length) {
            var ch = peek();
            if (ch == " " || ch == "\t" || ch == "\n" || ch == "\r") {
                advance();
            } else if (ch == "#") {
                // Skip comment until end of line
                while (peek() != "\n" && peek() != HxString.fromCharCode(0)) {
                    advance();
                }
            } else {
                break;
            }
        }
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

    private function readString(quote:String):Token {
        var value = "";
        advance(); // consume opening quote
        
        while (peek() != quote && peek() != HxString.fromCharCode(0)) {
            if (peek() == "\\") {
                advance();
                var escaped = peek();
                switch (escaped) {
                    case "n": value += "\n";
                    case "t": value += "\t";
                    case "r": value += "\r";
                    case "\\": value += "\\";
                    case '"': value += '"';
                    case "'": value += "'";
                    default: value += escaped;
                }
                advance();
            } else {
                value += advance();
            }
        }
        
        if (peek() == quote) advance(); // consume closing quote
        return TString(value);
    }

    private function readNumber():Token {
        var value = "";
        var isFloat = false;
        
        while (isDigit(peek())) {
            value += advance();
        }
        
        if (peek() == "." && isDigit(peek(1))) {
            isFloat = true;
            value += advance(); // consume dot
            while (isDigit(peek())) {
                value += advance();
            }
        }
        
        if (isFloat) {
            return TFloat(Std.parseFloat(value));
        } else {
            return TInt(Std.parseInt(value));
        }
    }

    private function readIdentifier():Token {
        var value = "";
        
        while (isAlphaNumeric(peek())) {
            value += advance();
        }
        
        return switch (value) {
            case "if": TIf;
            case "else": TElse;
            case "elif": TIf; // treat elif as if for now
            case "while": TWhile;
            case "for": TFor;
            case "in": TIn;
            case "def": TDef;
            case "return": TReturn;
            case "import": TImport;
            case "from": TFrom;
            case "as": TAs;
            case "True": TIdent("True");
            case "False": TIdent("False");
            case "None": TIdent("None");
            default: TIdent(value);
        };
    }

    public function nextToken():Token {
        skipWhitespace();
        
        if (pos >= source.length) {
            return TEOF;
        }
        
        var ch = peek();
        
        // Strings
        if (ch == '"' || ch == "'") {
            return readString(ch);
        }
        
        // Numbers
        if (isDigit(ch)) {
            return readNumber();
        }
        
        // Identifiers and keywords
        if (isAlpha(ch)) {
            return readIdentifier();
        }
        
        // Operators and punctuation
        advance();
        
        switch (ch) {
            case "+":
                if (peek() == "=") {
                    advance();
                    return TPlusEqual;
                } else if (peek() == "+") {
                    advance();
                    return TInc;
                }
                return TPlus;
            case "-":
                if (peek() == "-") {
                    advance();
                    return TDec;
                }
                return TMinus;
            case "*":
                return TMul;
            case "/":
                return TDiv;
            case "=":
                if (peek() == "=") {
                    advance();
                    return TEqualEqual;
                }
                return TEqual;
            case "!":
                if (peek() == "=") {
                    advance();
                    return TNotEqual;
                }
                return TNot;
            case "<":
                if (peek() == "=") {
                    advance();
                    return TLessEqual;
                }
                return TLess;
            case ">":
                if (peek() == "=") {
                    advance();
                    return TGreaterEqual;
                }
                return TGreater;
            case "&":
                if (peek() == "&") {
                    advance();
                    return TAnd;
                }
                throw new Error(SyntaxError("Unexpected character: &"), line, col);
            case "|":
                if (peek() == "|") {
                    advance();
                    return TOr;
                }
                throw new Error(SyntaxError("Unexpected character: |"), line, col);
            case "(":
                return TLParen;
            case ")":
                return TRParen;
            case "[":
                return TLBracket;
            case "]":
                return TRBracket;
            case ",":
                return TComma;
            case ".":
                return TDot;
            case ":":
                return TColon;
            default:
                throw new Error(SyntaxError("Unexpected character: " + ch), line, col);
        }
    }
}