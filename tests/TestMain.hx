package;

import paopao.hython.*;

class TestMain {
    static function main() {
        var source = "def add(x, y):\n  return x + y\n\nresult = add(2, 3)";
        try {
            var vm = new VM();
            var ast = new Lexer(source).tokenize();
            var code = new Parser(ast).parse();
            new Semantic().analyze(code);
            var bytes = new Compiler().compile(code);
            
            vm.execute(bytes);
            var result = vm.getGlobal("result");
            @:privateAccess trace("Result: " + vm.valueToString(result));  // "Result: 5"
        } catch (error:Dynamic) {
            trace("Error: " + error);
        }
    }
}