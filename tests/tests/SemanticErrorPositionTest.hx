package tests.tests;

import paopao.hython.Error;
import paopao.hython.Lexer;
import paopao.hython.Parser;
import paopao.hython.Semantic;
import tests.unit.TestCase;

class SemanticErrorPositionTest extends TestCase {
	public function new() {
		super();
	}

	public function testUndefinedVariableIncludesSourcePosition():Void {
		var error = runSemanticExpectError("unknown_name\n", "undefined variable: unknown_name");
		assertTrue(error.line > 0, "line should be non-zero");
		assertTrue(error.col > 0, "col should be non-zero");
	}

	public function testReturnOutsideFunctionIncludesSourcePosition():Void {
		var error = runSemanticExpectError("return 1\n", "return outside function");
		assertTrue(error.line > 0, "line should be non-zero");
		assertTrue(error.col > 0, "col should be non-zero");
	}

	public function testBreakOutsideLoopIncludesSourcePosition():Void {
		var error = runSemanticExpectError("break\n", "break outside loop");
		assertTrue(error.line > 0, "line should be non-zero");
		assertTrue(error.col > 0, "col should be non-zero");
	}

	public function testContinueOutsideLoopIncludesSourcePosition():Void {
		var error = runSemanticExpectError("continue\n", "continue outside loop");
		assertTrue(error.line > 0, "line should be non-zero");
		assertTrue(error.col > 0, "col should be non-zero");
	}

	private function runSemanticExpectError(source:String, expectedMessage:String):Error {
		var lexer = new Lexer(source);
		var tokens = lexer.tokenize();
		var program = new Parser(tokens, lexer.tokenPositions).parse();

		try {
			new Semantic().analyze(program, "semantic_test.py");
			fail("Expected semantic error");
		} catch (e:Error) {
			assertEquals(expectedMessage, e.errorMessage());
			return e;
		}

		throw "unreachable";
	}
}
