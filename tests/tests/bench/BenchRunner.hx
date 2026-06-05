package tests.bench;

import haxe.Timer;
import cpp.vm.Gc;

class BenchRunner {
	public static function run(name:String, fn:Void->Void, n:Int = 100000, warmup:Int = 1000) {
		
		// -----------------------
		// WARMUP PHASE
		// -----------------------
		for (i in 0...warmup) {
			fn();
		}

		// optional GC stabilize
		Gc.run(true);

		// -----------------------
		// MEASURE PHASE
		// -----------------------
		var start = Timer.stamp();

		for (i in 0...n) {
			fn();
		}

		var elapsed = Timer.stamp() - start;

		var avg = elapsed / n;
		var ops = 1 / avg;

		trace(name + " | avg: " + avg + " sec | " + Std.int(ops) + " ops/sec");
	}
}