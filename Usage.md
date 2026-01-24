# Usage

## Installation

To install Hython, you can use the following command:

```bash
haxelib install hython
```

Dev Build:

```bash
haxelib git hython https://github.com/Paopun20/hython.git
```

## Basic Usage

```haxe
import paopao.hython.Parser;
import paopao.hython.Interp;

// Simple execution
var code = "
def greet(name):
    return 'Hello, ' + name + '!'

print(greet('World'))
";

var parser = new Parser();
var expr = parser.parseString(code);
var interp = new Interp();
interp.execute(expr);
```

## Advanced Usage - Calling Specific Functions

```haxe
// Define your Python code
var code = "
def add(a, b):
    return a + b # do a + b and return the result

def multiply(a, b):
    return a * b # do a * b and return the result

def main(x, y):
    sum = add(x, y) # call add function with arguments x and y
    product = multiply(x, y) # call multiply function with arguments x and y
    print('Sum:', sum) # print the sum
    print('Product:', product) # print the product
    return {'sum': sum, 'product': product} # return a dictionary with sum and product
";

// Parse and execute to define functions
var parser = new Parser(); // Initialize parser instance
var expr = parser.parseString(code); // Parse the code string into an expression
var interp = new Interp(); // Initialize interpreter instance
interp.execute(expr); // Execute the parsed expression

// Call specific functions with arguments
var result = interp.calldef("main", [10, 5]); // Call main function with arguments 10 and 5
// Output:
// Sum: 15
// Product: 50

// Call individual functions
var sum = interp.calldef("add", [7, 3]); // Returns 10
var product = interp.calldef("multiply", [4, 6]); // Returns 24
```

## Setting Variables from Haxe

```haxe
var interp = new Interp(); // Initialize interpreter instance

// Set variables before executing code
interp.setVar("myValue", 42); // Set myValue variable to 42
interp.setVar("config", {debug: true, version: "1.0"}); // Set config variable to an object

var code = "
def process():
    print('Value:', myValue) # Print the value of myValue variable
    print('Debug mode:', config['debug']) # Print the value of debug property in config object
    return myValue * 2 # Return the value of myValue variable multiplied by 2
";

var parser = new Parser(); // Initialize parser instance
interp.execute(parser.parseString(code)); // Execute the parsed code
var result = interp.calldef("process", []); // Returns 84
```
