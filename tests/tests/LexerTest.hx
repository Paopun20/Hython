package tests;

import tests.unit.TestCase;
import paopao.hython.Lexer;
import paopao.hython.Ast;

class LexerTest extends TestCase {

    function tokens(input:String):Array<Token> {
        var lexer = new Lexer(input);
        return lexer.tokenize();
    }

    public function test_basic_assignment() {
        var t = tokens("x = 1");

        assertEquals(
            '[TIdent(x),TEqual,TInt(1),TEOF]',
            Std.string(t)
        );
    }

    public function test_math_expression() {
        var t = tokens("1 + 2 * 3");

        assertEquals(
            '[TInt(1),TPlus,TInt(2),TMul,TInt(3),TEOF]',
            Std.string(t)
        );
    }

    public function test_parentheses() {
        var t = tokens("(1 + 2)");

        assertEquals(
            '[TLParen,TInt(1),TPlus,TInt(2),TRParen,TEOF]',
            Std.string(t)
        );
    }

    public function test_complex_expression() {
        var t = tokens("x = 1 + 2 * (3 - 4)");

        assertEquals(
            '[TIdent(x),TEqual,TInt(1),TPlus,TInt(2),TMul,TLParen,TInt(3),TMinus,TInt(4),TRParen,TEOF]',
            Std.string(t)
        );
    }

    public function test_whitespace() {
        var t = tokens("   x   =   5   ");

        assertEquals(
            '[TIdent(x),TEqual,TInt(5),TEOF]',
            Std.string(t)
        );
    }

    public function test_invalid_character() {
        try {
            tokens("x = 1 @ 2");
            throw ("Expected error not thrown");
        } catch (e:Dynamic) {
            // pass
        }
    }
}