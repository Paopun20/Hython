package tests;

import tests.unit.TestCase;
import paopao.hython.Lexer;
import paopao.hython.Parser;
import paopao.hython.Ast;

class ParserTest extends TestCase {
	function parse(input:String):Expr {
		var parser = new Parser(input);
		return parser.parse();
	}

	function exprType(expr:Expr):String {
		return switch expr.expr {
			case EConstInt(_): "EConstInt";
			case EConstFloat(_): "EConstFloat";
			case EConstString(_): "EConstString";
			case EConstBool(_): "EConstBool";
			case EConstNone: "EConstNone";
			case EVar(_): "EVar";
			case EAssign(_, _, _): "EAssign";
			case EBinop(_, _, _): "EBinop";
			case EUnop(_, _): "EUnop";
			case EIf(_, _, _): "EIf";
			case EWhile(_, _): "EWhile";
			case EBlock(_): "EBlock";
			case EFunction(_, _): "EFunction";
			case ECall(_, _): "ECall";
			case EReturn(_): "EReturn";
			case EObject(_): "EObject";
			case EField(_, _): "EField";
			case EIndex(_, _): "EIndex";
			case EImport(_, _): "EImport";
			case EImportFrom(_, _): "EImportFrom";
			case ESwitch(_, _, _): "ESwitch";
			case EInfo(_): "EInfo";
		};
	}

	function getBlockExprs(ast:Expr):Array<Expr> {
		return switch ast.expr {
			case EBlock(exprs): exprs;
			default: [];
		};
	}

	public function test_integer_literal() {
		var ast = parse("42");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EConstInt", exprType(exprs[0]));
	}

	public function test_float_literal() {
		var ast = parse("3.14");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EConstFloat", exprType(exprs[0]));
	}

	public function test_string_literal() {
		var ast = parse('"hello"');
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EConstString", exprType(exprs[0]));
	}

	public function test_simple_addition() {
		var ast = parse("1 + 2");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EBinop", exprType(exprs[0]));
	}

	public function test_operator_precedence() {
		var ast = parse("1 + 2 * 3");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EBinop", exprType(exprs[0]));
	}

	public function test_parentheses_override_precedence() {
		var ast = parse("(1 + 2) * 3");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EBinop", exprType(exprs[0]));
	}

	public function test_simple_assignment() {
		var ast = parse("x = 5");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EAssign", exprType(exprs[0]));
	}

	public function test_unary_minus() {
		var ast = parse("-5");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EUnop", exprType(exprs[0]));
	}

	public function test_if_statement() {
		var ast = parse("if x:\ny = 1");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EIf", exprType(exprs[0]));
	}

	public function test_while_loop() {
		var ast = parse("while x:\nx = x - 1");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EWhile", exprType(exprs[0]));
	}

	public function test_function_definition() {
		var ast = parse("def f(x):\nx + 1");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		// Function definitions are now parsed as assignments: f = def(x): ...
		assertEquals("EAssign", exprType(exprs[0]));
	}

	public function test_function_call() {
		var ast = parse("f(1, 2, 3)");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("ECall", exprType(exprs[0]));
	}

	public function test_return_statement() {
		var ast = parse("return 42");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EReturn", exprType(exprs[0]));
	}

	public function test_field_access() {
		var ast = parse("obj.field");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EField", exprType(exprs[0]));
	}

	public function test_index_access() {
		var ast = parse("arr[0]");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(1, exprs.length);
		assertEquals("EIndex", exprType(exprs[0]));
	}

	public function test_multiple_statements() {
		var ast = parse("x = 1\ny = 2\nz = 3");
		var exprs = getBlockExprs(ast);

		assertEquals("EBlock", exprType(ast));
		assertEquals(3, exprs.length);
		assertEquals("EAssign", exprType(exprs[0]));
		assertEquals("EAssign", exprType(exprs[1]));
		assertEquals("EAssign", exprType(exprs[2]));
	}
}
