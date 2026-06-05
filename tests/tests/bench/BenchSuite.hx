package tests.bench;

import tests.bench.BenchRunner;

import paopao.hython.Interpreter;

class BenchSuite {
	public static function main() {
		var interpreter = new Interpreter("<bench>");

		loadPrograms(interpreter);

		// 1. Function Call
		BenchRunner.run("function call", () -> {
			interpreter.callDef("call_main", []);
		});

		// 2. Arithmetic
		BenchRunner.run("arithmetic", () -> {
			interpreter.callDef("arith_main", []);
		});

		// 3. Loop
		BenchRunner.run("loop", () -> {
			interpreter.callDef("loop_main", []);
		});

		// 4. Branch
		BenchRunner.run("branch", () -> {
			interpreter.callDef("branch_main", []);
		});

		// 5. Local access
		BenchRunner.run("locals", () -> {
			interpreter.callDef("local_main", []);
		});

		// 6. Allocation / list ops
		BenchRunner.run("allocation", () -> {
			interpreter.callDef("alloc_main", []);
		});
	}

	// BENCH CODE
	static function loadPrograms(interpreter:Interpreter) {

		interpreter.run("
def call_main():
    pass
");

		interpreter.run("
def arith_main():
    x = 1 + 2 + 3 + 4
    y = x * 2
    z = y - 5
");

		interpreter.run("
def loop_main():
    s = 0
    for i in range(1000):
        s += i
");

		interpreter.run("
def branch_main():
    x = 0
    for i in range(1000):
        if i % 2 == 0:
            x += 1
        else:
            x -= 1
");

		interpreter.run("
def local_main():
    a = 1
    b = 2
    c = 3
    d = a + b + c
");

		interpreter.run("
def alloc_main():
    lst = []
    for i in range(100):
        lst.append(i)
");
	}
}