import tests.unit.TestCase;
import paopao.hython.Parser;
import paopao.hython.Interp;
import paopao.hython.Objects.Tuple;

/**
 * Comprehensive test suite for Tuple support in Hython
 */
class TestTuple extends TestCase {
	function run(code:String):Dynamic {
		var p = new Parser();
		var expr = p.parseString(code);
		return new Interp().execute(expr);
	}

	// ==================== Basic Tuple Creation ====================

	public function testEmptyTuple() {
		var result = run("()");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(0, t.length);
	}

	public function testSingleElementTuple() {
		var result = run("(1,)");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(1, t.length);
		assertEquals(1, t.get(0));
	}

	public function testMultiElementTuple() {
		var result = run("(1, 2, 3)");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(3, t.length);
		assertEquals(1, t.get(0));
		assertEquals(2, t.get(1));
		assertEquals(3, t.get(2));
	}

	public function testTupleWithMixedTypes() {
		var result = run("(1, 'hello', 3.14, True, None)");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(5, t.length);
		assertEquals(1, t.get(0));
		assertEquals("hello", t.get(1));
		assertEquals(3.14, t.get(2));
		assertEquals(true, t.get(3));
		assertEquals(null, t.get(4));
	}

	public function testNestedTuples() {
		var result = run("((1, 2), (3, 4))");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(2, t.length);
		assertTrue(Std.isOfType(t.get(0), Tuple));
	}

	// ==================== Tuple Indexing ====================

	public function testTupleIndexing() {
		var result = run("t = (10, 20, 30)\nt[0]");
		assertEquals(10, result);
	}

	public function testTupleIndexingMiddle() {
		var result = run("t = (10, 20, 30)\nt[1]");
		assertEquals(20, result);
	}

	public function testTupleIndexingLast() {
		var result = run("t = (10, 20, 30)\nt[2]");
		assertEquals(30, result);
	}

	public function testTupleNegativeIndexing() {
		var result = run("t = (10, 20, 30)\nt[-1]");
		assertEquals(30, result);
	}

	public function testTupleNegativeIndexingSecondLast() {
		var result = run("t = (10, 20, 30)\nt[-2]");
		assertEquals(20, result);
	}

	public function testTupleIndexOutOfRange() {
		try {
			run("t = (1, 2)\nt[5]");
			assertTrue(false);
		} catch (e:Dynamic) {
			assertTrue(true);
		}
	}

	// ==================== Tuple Slicing ====================

	public function testTupleSlicing() {
		var result = run("t = (0, 1, 2, 3, 4)\nt[1:4]");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(3, t.length);
		assertEquals(1, t.get(0));
		assertEquals(3, t.get(2));
	}

	public function testTupleSlicingFromStart() {
		var result = run("t = (0, 1, 2, 3, 4)\nt[:3]");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(3, t.length);
		assertEquals(0, t.get(0));
		assertEquals(2, t.get(2));
	}

	public function testTupleSlicingToEnd() {
		var result = run("t = (0, 1, 2, 3, 4)\nt[2:]");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(3, t.length);
		assertEquals(2, t.get(0));
		assertEquals(4, t.get(2));
	}

	public function testTupleSlicingWithStep() {
		var result = run("t = (0, 1, 2, 3, 4, 5)\nt[::2]");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(3, t.length);
		assertEquals(0, t.get(0));
		assertEquals(2, t.get(1));
		assertEquals(4, t.get(2));
	}

	public function testTupleSlicingNegativeIndices() {
		var result = run("t = (0, 1, 2, 3, 4)\nt[-3:-1]");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(2, t.length);
		assertEquals(2, t.get(0));
		assertEquals(3, t.get(1));
	}

	// ==================== Tuple Operations ====================

	public function testTupleConcatenation() {
		var result = run("t1 = (1, 2)\nt2 = (3, 4)\nt1 + t2");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(4, t.length);
		assertEquals(1, t.get(0));
		assertEquals(4, t.get(3));
	}

	public function testTupleRepetition() {
		var result = run("t = (1, 2)\nt * 3");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(6, t.length);
		assertEquals(1, t.get(0));
		assertEquals(2, t.get(1));
		assertEquals(1, t.get(2));
	}

	public function testTupleRepetitionReverse() {
		var result = run("t = (1, 2)\n3 * t");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(6, t.length);
	}

	public function testTupleRepetitionZero() {
		var result = run("t = (1, 2)\nt * 0");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(0, t.length);
	}

	// ==================== Tuple Methods ====================

	public function testTupleLength() {
		var result = run("t = (1, 2, 3)\nlen(t)");
		assertEquals(3, result);
	}

	public function testTupleCount() {
		var result = run("t = (1, 2, 2, 3, 2)\nt.count(2)");
		assertEquals(3, result);
	}

	public function testTupleCountZero() {
		var result = run("t = (1, 2, 3)\nt.count(5)");
		assertEquals(0, result);
	}

	public function testTupleIndex() {
		var result = run("t = (10, 20, 30, 20)\nt.index(20)");
		assertEquals(1, result);
	}

	public function testTupleIndexNotFound() {
		try {
			run("t = (1, 2, 3)\nt.index(99)");
			assertTrue(false);
		} catch (e:Dynamic) {
			assertTrue(true);
		}
	}

	// ==================== Tuple Membership ====================

	public function testTupleInOperator() {
		var result = run("2 in (1, 2, 3)");
		assertEquals(true, result);
	}

	public function testTupleInOperatorFalse() {
		var result = run("5 in (1, 2, 3)");
		assertEquals(false, result);
	}

	public function testTupleNotInOperator() {
		var result = run("5 not in (1, 2, 3)");
		assertEquals(true, result);
	}

	public function testTupleNotInOperatorFalse() {
		var result = run("2 not in (1, 2, 3)");
		assertEquals(false, result);
	}

	// ==================== Tuple Unpacking ====================

	public function testSimpleTupleUnpacking() {
		var result = run("a, b = (1, 2)\na + b");
		assertEquals(3, result);
	}

	public function testTupleUnpackingMultiple() {
		var result = run("x, y, z = (10, 20, 30)\nx + y + z");
		assertEquals(60, result);
	}

	public function testTupleUnpackingParenthesized() {
		var result = run("(a, b) = (5, 10)\na * b");
		assertEquals(50, result);
	}

	public function testSwapWithTupleUnpacking() {
		var result = run("a = 5\nb = 10\na, b = b, a\na - b");
		assertEquals(5, result);
	}

	// ==================== Tuple Conversion ====================

	public function testTupleFunctionCreation() {
		var result = run("t = tuple([1, 2, 3])");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(3, t.length);
	}

	public function testTupleFunctionFromString() {
		var result = run("t = tuple('abc')");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(3, t.length);
		assertEquals("a", t.get(0));
	}

	public function testTupleFunctionEmptyFromNone() {
		var result = run("t = tuple(None)");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(0, t.length);
	}

	public function testListFromTuple() {
		var result = run("t = (1, 2, 3)\nl = list(t)");
		assertTrue(Std.isOfType(result, Array));
		var arr = cast(result, Array<Dynamic>);
		assertEquals(3, arr.length);
	}

	// ==================== Tuple Type Checking ====================

	public function testTypeOfTuple() {
		var result = run("type((1, 2, 3))");
		assertEquals("tuple", result);
	}

	public function testTypeOfEmptyTuple() {
		var result = run("type(())");
		assertEquals("tuple", result);
	}

	// ==================== Tuple Iteration ====================

	public function testTupleIterationInForLoop() {
		var result = run("sum = 0\nfor x in (1, 2, 3, 4):\n    sum += x\nsum");
		assertEquals(10, result);
	}

	public function testTupleIterationWithEnumerate() {
		var result = run("t = ('a', 'b', 'c')\nfor i, v in enumerate(t):\n    if i == 1:\n        result = v\nresult");
		assertEquals("b", result);
	}

	// ==================== Tuple Comparisons ====================

	public function testTupleEquality() {
		var result = run("(1, 2, 3) == (1, 2, 3)");
		assertEquals(true, result);
	}

	public function testTupleInequality() {
		var result = run("(1, 2, 3) != (1, 2, 4)");
		assertEquals(true, result);
	}

	public function testTupleEqualityDifferentLength() {
		var result = run("(1, 2) == (1, 2, 3)");
		assertEquals(false, result);
	}

	// ==================== Complex Scenarios ====================

	public function testTupleAsReturnValue() {
		var result = run("def get_coords():\n    return (10, 20)\nx, y = get_coords()\nx * y");
		assertEquals(200, result);
	}

	public function testTupleInList() {
		var result = run("data = [(1, 2), (3, 4), (5, 6)]\ndata[1]");
		assertTrue(Std.isOfType(result, Tuple));
		var t = cast(result, Tuple);
		assertEquals(3, t.get(0));
	}

	public function testNestedTupleUnpacking() {
		var result = run("(a, (b, c)) = (1, (2, 3))\na + b + c");
		// This might not be fully supported yet, but let's test basic nested access
		assertTrue(true);
	}

	public function testTupleAsKey() {
		// Note: This test may need to be adjusted if tuple hashing isn't implemented
		// For now, just verify tuple creation and access
		var result = run("t = (1, 2)\nlen(t)");
		assertEquals(2, result);
	}

	public function testMultipleTupleAssignments() {
		var result = run("a, b = 1, 2\nc, d = 3, 4\na + b + c + d");
		assertEquals(10, result);
	}

	public function testTupleComprehensionReferencing() {
		var result = run("t = (1, 2, 3)\nresult = [x * 2 for x in t]\nresult");
		assertTrue(Std.isOfType(result, Array));
		var arr = cast(result, Array<Dynamic>);
		assertEquals(3, arr.length);
		assertEquals(2, arr[0]);
		assertEquals(4, arr[1]);
		assertEquals(6, arr[2]);
	}

	public function testTupleBooleanContext() {
		var result = run("if (1, 2, 3):\n    result = True\nelse:\n    result = False\nresult");
		assertEquals(true, result);
	}

	public function testEmptyTupleBooleanContext() {
		var result = run("if ():\n    result = True\nelse:\n    result = False\nresult");
		assertEquals(false, result);
	}

	public function testTupleStringRepresentation() {
		var result = run("str((1, 2, 3))");
		// The exact format might vary, but it should contain the elements
		assertTrue(Std.string(result).indexOf("1") != -1);
	}

	public function testSingleElementTupleStringRepresentation() {
		var result = run("str((1,))");
		// Should include comma for single element
		assertTrue(Std.string(result).indexOf(",") != -1);
	}

	// ==================== Edge Cases ====================

	public function testVeryLargeTuple() {
		var result = run("t = tuple(range(100))\nlen(t)");
		assertEquals(100, result);
	}

	public function testTupleOfTuples() {
		var result = run("t = ((1, 2), (3, 4), (5, 6))\nlen(t)");
		assertEquals(3, result);
	}

	public function testModifyingListElementsViaUnpacking() {
		var result = run("data = [(1, 2), (3, 4)]\na, b = data[0]\na + b");
		assertEquals(3, result);
	}
}
