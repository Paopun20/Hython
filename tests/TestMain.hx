package;

import tests.unit.TestRunner;
import tests.tests.*;
import tests.bench.BenchSuite;
#if cpp
import cpp.vm.Gc;
#end

class TestMain {
	static function fmt(b:Float):String {
		if (b >= 1048576)
			return '${Math.round(b / 10485.76) / 100} MB';
		if (b >= 1024)
			return '${Math.round(b / 10.24) / 100} KB';
		return '${b} B';
	}

	static function main() {
		var runner = new TestRunner(true);
		runner.add(new Test1());
		runner.add(new TestClass());

		#if cpp
		Gc.compact(); // collect before baseline so delta is meaningful
		final before = Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#end

		final ok = runner.run();

		#if cpp
		Gc.compact();
		final before = Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#end

		final ok = runner.run();

		#if cpp
		Gc.compact();
		final after = Gc.memInfo64(Gc.MEM_INFO_USAGE);
		final reserved = Gc.memInfo64(Gc.MEM_INFO_RESERVED);
		final large = Gc.memInfo64(Gc.MEM_INFO_LARGE);

		Sys.println('-- memory after tests --');
		Sys.println('  retained delta : ${fmt(after - before)}');
		Sys.println('  heap reserved  : ${fmt(reserved)}');
		Sys.println('  large-obj pool : ${fmt(large)}');
		#end

		if (!ok)
			Sys.exit(1);

		// BenchSuite.main(); // Nope
	}
}
