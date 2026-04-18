import paopao.hython.Interp;

class TestFuncDebug {
	static function main() {
		trace("Test 1: Simple function");
		var r1 = Interp.runFromSource("
def add(a, b):
    return a + b
add(3, 4)
		");
		trace("Result: " + r1); // Should be 7

		trace("Test 2: Function with constant");
		var r2 = Interp.runFromSource("
def get_five():
    return 5
get_five()
		");
		trace("Result: " + r2); // Should be 5

		trace("Test 3: Simple recursion");
		var r3 = Interp.runFromSource("
def countdown(n):
    if n <= 0:
        return 0
    return countdown(n - 1)
countdown(3)
		");
		trace("Result: " + r3); // Should be 0

		trace("Test 4: Fibonacci");
		var r4 = Interp.runFromSource("
def fib(n):
    if n <= 1:
        return n
    return fib(n-1) + fib(n-2)
fib(10)
		");
		trace("Result: " + r4); // Should be 55
	}
}
