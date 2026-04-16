package tests;

import tests.unit.TestCase;
import paopao.hython.Lexer;
import paopao.hython.Parser;
import paopao.hython.Interp;
import paopao.hython.Ast;

class InterpTest extends TestCase {

	function eval(source:String):Dynamic {
		var parser = new Parser(source);
		var ast = parser.parse();
		var interp = new Interp();
		return interp.run(ast);
	}

	public function test_integer_literal() {
		var result = eval("42");
		assertEquals(42, result);
	}

	public function test_float_literal() {
		var result = eval("3.14");
		assertTrue(Std.isOfType(result, Float));
	}

	public function test_string_literal() {
		var result = eval('"hello"');
		assertEquals("hello", result);
	}

	public function test_boolean_true() {
		var result = eval("True");
		assertEquals(true, result);
	}

	public function test_boolean_false() {
		var result = eval("False");
		assertEquals(false, result);
	}

	public function test_none_literal() {
		var result = eval("None");
		assertEquals(null, result);
	}

	public function test_simple_addition() {
		var result = eval("1 + 2");
		assertEquals(3, result);
	}

	public function test_simple_subtraction() {
		var result = eval("5 - 3");
		assertEquals(2, result);
	}

	public function test_simple_multiplication() {
		var result = eval("4 * 3");
		assertEquals(12, result);
	}

	public function test_simple_division() {
		var result = eval("10 / 2");
		assertEquals(5.0, result);
	}

	public function test_operator_precedence() {
		var result = eval("1 + 2 * 3");
		assertEquals(7, result);
	}

	public function test_parentheses_override_precedence() {
		var result = eval("(1 + 2) * 3");
		assertEquals(9, result);
	}

	public function test_unary_minus() {
		var result = eval("-5");
		assertEquals(-5, result);
	}

	public function test_string_concatenation() {
		var result = eval('"hello" + " " + "world"');
		assertEquals("hello world", result);
	}

	public function test_multiple_statements() {
		var result = eval("1\n2\n3");
		assertEquals(3, result);
	}

	public function test_simple_variable_assignment() {
		var result = eval("x = 5\nx");
		assertEquals(5, result);
	}

	public function test_variable_update() {
		var result = eval("x = 5\nx = 10\nx");
		assertEquals(10, result);
	}

	public function test_compound_assignment_add() {
		var result = eval("x = 5\nx += 3\nx");
		assertEquals(8, result);
	}

	public function test_if_true() {
		var result = eval("if True:\n42");
		assertEquals(42, result);
	}

	public function test_if_false() {
		var result = eval("if False:\n42");
		assertEquals(null, result);
	}

	public function test_if_else_true() {
		var result = eval("if True:\n42\nelse:\n100");
		assertEquals(42, result);
	}

	public function test_if_else_false() {
		var result = eval("if False:\n42\nelse:\n100");
		assertEquals(100, result);
	}

	public function test_while_loop() {
		var result = eval("x = 0\nwhile x < 3:\nx = x + 1\nx");
		assertEquals(3, result);
	}

	public function test_return_statement() {
		var result = eval("return 42");
		assertEquals(42, result);
	}

	public function test_function_definition_and_call() {
		var result = eval("def add(a, b):\na + b\nadd(2, 3)");
		assertEquals(5, result);
	}

	public function test_function_with_return() {
		var result = eval("def multiply(x, y):\nreturn x * y\nmultiply(4, 5)");
		assertEquals(20, result);
	}

	public function test_nested_function_calls() {
		var result = eval("def add(a, b):\nreturn a + b\ndef mul(x, y):\nreturn x * y\nadd(mul(2, 3), 4)");
		assertEquals(10, result);
	}

	public function test_string_indexing() {
		var result = eval('"hello"[0]');
		assertEquals("h", result);
	}

	public function test_comparison_equal() {
		var result = eval("5 == 5");
		assertEquals(true, result);
	}

	public function test_comparison_not_equal() {
		var result = eval("5 != 3");
		assertEquals(true, result);
	}

	public function test_comparison_less_than() {
		var result = eval("3 < 5");
		assertEquals(true, result);
	}

	public function test_comparison_greater_than() {
		var result = eval("5 > 3");
		assertEquals(true, result);
	}

	public function test_logical_and_true() {
		var result = eval("True && True");
		assertEquals(true, result);
	}

	public function test_logical_and_false() {
		var result = eval("True && False");
		assertEquals(false, result);
	}

	public function test_logical_or_true() {
		var result = eval("True || False");
		assertEquals(true, result);
	}

	public function test_logical_or_false() {
		var result = eval("False || False");
		assertEquals(false, result);
	}

	public function test_not_operator() {
		var result = eval("!True");
		assertEquals(false, result);
	}

	public function test_increment_operator() {
		var result = eval("x = 5\n++x");
		assertEquals(6, result);
	}

	public function test_decrement_operator() {
		var result = eval("x = 5\n--x");
		assertEquals(4, result);
	}

	public function test_truthy_non_zero_int() {
		var result = eval("if 1:\n42");
		assertEquals(42, result);
	}

	public function test_truthy_zero_int() {
		var result = eval("if 0:\n42\nelse:\n100");
		assertEquals(100, result);
	}

	public function test_truthy_non_empty_string() {
		var result = eval('if "hello":\n42');
		assertEquals(42, result);
	}

	public function test_truthy_empty_string() {
		var result = eval('if "":\n42\nelse:\n100');
		assertEquals(100, result);
	}
}
