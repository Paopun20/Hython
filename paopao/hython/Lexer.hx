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

    // indentation
    TIndent;
    TDedent;
    TNewline;

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
    private var indentationStyle:String; // "spaces" or "tabs"
    private var indentStack:Array<Int>;
    private var pendingTokens:Array<Token>;
    private var atLineStart:Bool;

    public function new(source:String) {
        this.source = source;
        this.tokens = [];
        this.pos = 0;
        this.line = 1;
        this.col = 1;
        this.indentationStyle = null;
        this.indentStack = [0];
        this.pendingTokens = [];
        this.atLineStart = true;
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

    // Skips spaces, tabs, carriage returns — but NOT newlines (they are significant)
    private function skipWhitespace():Void {
        while (pos < source.length) {
            var ch = peek();
            if (ch == " " || ch == "\t" || ch == "\r") {
                advance();
            } else if (ch == "#") {
                // Skip comment until end of line (but leave the \n)
                while (peek() != "\n" && peek() != HxString.fromCharCode(0)) {
                    advance();
                }
            } else {
                break;
            }
        }
    }

    private function validateLineIndentation(indentChars:String):Void {
        if (indentChars.length > 0) {
            var hasSpaces = indentChars.indexOf(" ") >= 0;
            var hasTabs = indentChars.indexOf("\t") >= 0;

            if (hasSpaces && hasTabs) {
                throw new Error(TabError("inconsistent use of tabs and spaces in indentation"), line, col);
            }

            if (indentationStyle == null) {
                indentationStyle = hasSpaces ? "spaces" : "tabs";
            } else {
                var currentStyle = hasSpaces ? "spaces" : "tabs";
                if (indentationStyle != currentStyle) {
                    throw new Error(TabError("inconsistent use of tabs and spaces in indentation"), line, col);
                }
            }
        }
    }

    // Measures indentation at the current position and emits TIndent/TDedent tokens
    // into pendingTokens as needed. Consumes the indent characters from the source.
    private function processIndentation():Void {
        var indentChars = "";
        while (peek(indentChars.length) == " " || peek(indentChars.length) == "\t") {
            indentChars += peek(indentChars.length);
        }

        // Skip blank lines and comment-only lines — do not emit indent/dedent
        var nextCh = peek(indentChars.length);
        if (nextCh == "\n" || nextCh == "#" || nextCh == HxString.fromCharCode(0)) return;

        // Validate no mixed tabs + spaces on this line
        validateLineIndentation(indentChars);

        // Consume the indent characters
        for (i in 0...indentChars.length) advance();

        var level = indentChars.length;
        var current = indentStack[indentStack.length - 1];

        if (level > current) {
            indentStack.push(level);
            pendingTokens.push(TIndent);
        } else if (level < current) {
            while (indentStack[indentStack.length - 1] != level) {
                if (indentStack.length <= 1) {
                    throw new Error(
                        IndentationError("unindent does not match any outer indentation level"),
                        line, col
                    );
                }
                indentStack.pop();
                pendingTokens.push(TDedent);
            }
        }
        // level == current: no token needed
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
                    case "n":  value += "\n";
                    case "t":  value += "\t";
                    case "r":  value += "\r";
                    case "\\": value += "\\";
                    case '"':  value += '"';
                    case "'":  value += "'";
                    default:   value += escaped;
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

        return isFloat ? TFloat(Std.parseFloat(value)) : TInt(Std.parseInt(value));
    }

    private function readIdentifier():Token {
        var value = "";

        while (isAlphaNumeric(peek())) {
            value += advance();
        }

        return switch (value) {
            case "if":     TIf;
            case "else":   TElse;
            case "elif":   TIf; // treat elif as if for now
            case "while":  TWhile;
            case "for":    TFor;
            case "in":     TIn;
            case "def":    TDef;
            case "return": TReturn;
            case "import": TImport;
            case "from":   TFrom;
            case "as":     TAs;
            case "True":   TIdent("True");
            case "False":  TIdent("False");
            case "None":   TIdent("None");
            default:       TIdent(value);
        };
    }

    public function nextToken():Token {
        // 1. Drain any pending INDENT/DEDENT tokens first
        if (pendingTokens.length > 0) {
            return pendingTokens.shift();
        }

        // 2. At the start of a new line, process indentation
        if (atLineStart) {
            atLineStart = false;
            processIndentation();
            if (pendingTokens.length > 0) {
                return pendingTokens.shift();
            }
        }

        // 3. Skip inline whitespace (spaces/tabs/comments — not newlines)
        skipWhitespace();

        // 4. End of file: emit remaining DEDENTs then EOF
        if (pos >= source.length) {
            if (indentStack.length > 1) {
                indentStack.pop();
                // Queue remaining dedents
                while (indentStack.length > 1) {
                    indentStack.pop();
                    pendingTokens.push(TDedent);
                }
                return TDedent;
            }
            return TEOF;
        }

        var ch = peek();

        // 5. Newlines are significant — emit TNewline and mark next line start
        if (ch == "\n") {
            advance();
            atLineStart = true;
            return TNewline;
        }

        // 6. Strings
        if (ch == '"' || ch == "'") {
            return readString(ch);
        }

        // 7. Numbers
        if (isDigit(ch)) {
            return readNumber();
        }

        // 8. Identifiers and keywords
        if (isAlpha(ch)) {
            return readIdentifier();
        }

        // 9. Operators and punctuation
        advance();

        switch (ch) {
            case "+":
                if (peek() == "=") { advance(); return TPlusEqual; }
                if (peek() == "+") { advance(); return TInc; }
                return TPlus;
            case "-":
                if (peek() == "-") { advance(); return TDec; }
                return TMinus;
            case "*":
                return TMul;
            case "/":
                return TDiv;
            case "=":
                if (peek() == "=") { advance(); return TEqualEqual; }
                return TEqual;
            case "!":
                if (peek() == "=") { advance(); return TNotEqual; }
                return TNot;
            case "<":
                if (peek() == "=") { advance(); return TLessEqual; }
                return TLess;
            case ">":
                if (peek() == "=") { advance(); return TGreaterEqual; }
                return TGreater;
            case "&":
                if (peek() == "&") { advance(); return TAnd; }
                throw new Error(SyntaxError("Unexpected character: &"), line, col);
            case "|":
                if (peek() == "|") { advance(); return TOr; }
                throw new Error(SyntaxError("Unexpected character: |"), line, col);
            case "(": return TLParen;
            case ")": return TRParen;
            case "[": return TLBracket;
            case "]": return TRBracket;
            case ",": return TComma;
            case ".": return TDot;
            case ":": return TColon;
            default:
                throw new Error(SyntaxError("Unexpected character: " + ch), line, col);
        }
    }
}
