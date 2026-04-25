package;

import paopao.hython.*;

class TestMain {
	static function main() {

		// 🔹 1. source code ที่จะ test
		var source = "
x = 1 + 2
";

		// 🔹 2. Lexer
		var lexer = new Lexer(source);
		var tokens = lexer.tokenize();
		trace("TOKENS: " + tokens);

		// 🔹 3. Parser
		var parser = new Parser(tokens);
		var ast = parser.parse();
		trace("AST: " + ast);

		// 🔹 4. Semantic
		var semantic = new Semantic();
		semantic.analyze(ast);
		trace("Semantic OK");

		// 🔹 5. Code Generation
	}
}