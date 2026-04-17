import paopao.hython.Lexer;

class TestIndentation {
    static function main() {
        // Test 1: Spaces for indentation
        var code1 = "def foo():
    x = 1
    y = 2
    if x > 0:
        print(x)";

        trace("=== Test 1: Spaces Indentation ===");
        var lexer1 = new Lexer(code1);
        var tokens1 = lexer1.tokenize();
        for (token in tokens1) {
            trace(tokenToString(token));
        }

        // Test 2: Tabs for indentation
        var code2 = "def bar():
\tx = 1
\tif x > 0:
\t\tprint(x)";

        trace("\n=== Test 2: Tabs Indentation ===");
        var lexer2 = new Lexer(code2);
        var tokens2 = lexer2.tokenize();
        for (token in tokens2) {
            trace(tokenToString(token));
        }

        // Test 3: Mixed nested indentation
        var code3 = "for i in range(10):
    if i > 5:
        while True:
            x = i";

        trace("\n=== Test 3: Nested Indentation ===");
        var lexer3 = new Lexer(code3);
        var tokens3 = lexer3.tokenize();
        for (token in tokens3) {
            trace(tokenToString(token));
        }
    }

    static function tokenToString(token:paopao.hython.Lexer.Token):String {
        return switch token {
            case TIdent(s): "IDENT(" + s + ")";
            case TInt(n): "INT(" + n + ")";
            case TFloat(f): "FLOAT(" + f + ")";
            case TString(s): "STRING(\"" + s + "\")";
            case TIndent: "INDENT";
            case TDedent: "DEDENT";
            case TNewline: "NEWLINE";
            case TColon: ":";
            case TEqual: "=";
            case TEqualEqual: "==";
            case TIf: "IF";
            case TElse: "ELSE";
            case TDef: "DEF";
            case TReturn: "RETURN";
            case TFor: "FOR";
            case TIn: "IN";
            case TWhile: "WHILE";
            case TPlus: "+";
            case TMinus: "-";
            case TMul: "*";
            case TDiv: "/";
            case TLParen: "(";
            case TRParen: ")";
            case TComma: ",";
            case TEOF: "EOF";
            default: "TOKEN";
        };
    }
}
