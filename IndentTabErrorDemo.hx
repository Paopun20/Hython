import paopao.hython.Error;
import paopao.hython.Lexer;

class IndentErrorDemo {
    static function main():Void {
        Sys.println("=== Hython Indentation Error Demo ===\n");
        
        // Example 1: TabError - mixing tabs and spaces
        Sys.println("Example 1: TabError (mixing tabs and spaces)");
        Sys.println("Code:");
        Sys.println("def greet(name):");
        Sys.println("    print(f\"Hello, {name}!\")  # 4 spaces");
        Sys.println("\tprint(\"Welcome to Real Python!\")  # 1 tab");
        Sys.println("greet(\"Ada\")\n");
        
        var mixedCode = "def greet(name):\n    print(f\"Hello, {name}!\")\n\tprint(\"Welcome!\")";
        var lexer1 = new Lexer(mixedCode);
        
        try {
            lexer1.tokenize();
        } catch (e:Error) {
            Sys.println("Error Type: " + e.errorName());
            Sys.println("Error Message: " + e.errorMessage());
            Sys.println("Location: Line " + e.line + ", Column " + e.col);
        }
        
        Sys.println("\n==================================================\n");
        
        // Example 2: Consistent spaces (valid)
        Sys.println("Example 2: Consistent space indentation (valid)");
        Sys.println("Code:");
        Sys.println("def calculate_area(radius):");
        Sys.println("    area = 3.14 * radius ** 2");
        Sys.println("    return area\n");
        
        var spacesCode = "def calculate_area(radius):\n    area = 3.14 * radius ** 2\n    return area";
        var lexer2 = new Lexer(spacesCode);
        
        try {
            var tokens = lexer2.tokenize();
            Sys.println("✓ Code tokenized successfully!");
            Sys.println("  Tokens generated: " + tokens.length);
        } catch (e:Error) {
            Sys.println("✗ Unexpected error: " + e.errorName());
        }
        
        Sys.println("\n==================================================\n");
        
        // Example 3: Consistent tabs (valid)
        Sys.println("Example 3: Consistent tab indentation (valid)");
        Sys.println("Code:");
        Sys.println("def greet(name):");
        Sys.println("\tif name:");
        Sys.println("\t\tprint(\"Hello, \" + name)\n");
        
        var tabsCode = "def greet(name):\n\tif name:\n\t\tprint(\"Hello, \" + name)";
        var lexer3 = new Lexer(tabsCode);
        
        try {
            var tokens = lexer3.tokenize();
            Sys.println("✓ Code tokenized successfully!");
            Sys.println("  Tokens generated: " + tokens.length);
        } catch (e:Error) {
            Sys.println("✗ Unexpected error: " + e.errorName());
        }
        
        Sys.println("\n=== Demo Complete ===");
    }
}
