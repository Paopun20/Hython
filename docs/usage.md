# Usage Guide

## Installation

```bash
haxelib install hython
```

Dev Build:

```bash
haxelib git hython https://github.com/Paopun20/hython.git dev
```

## Basic Usage

```haxe
import paopao.hython.Parser;
import paopao.hython.Interp;

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

## Calling Specific Functions

```haxe
var code = "
def add(a, b):
    return a + b

def multiply(a, b):
    return a * b

def main(x, y):
    sum = add(x, y)
    product = multiply(x, y)
    print('Sum:', sum)
    print('Product:', product)
    return {'sum': sum, 'product': product}
";

var parser = new Parser();
var expr = parser.parseString(code);
var interp = new Interp();
interp.execute(expr);

var result = interp.calldef("main", [10, 5]);
var sum = interp.calldef("add", [7, 3]);
var product = interp.calldef("multiply", [4, 6]);
```

## Setting Variables from Haxe

```haxe
var interp = new Interp();

interp.setVar("myValue", 42);
interp.setVar("config", {debug: true, version: "1.0"});

var code = "
def process():
    print('Value:', myValue)
    print('Debug mode:', config['debug'])
    return myValue * 2
";

var parser = new Parser();
interp.execute(parser.parseString(code));
var result = interp.calldef("process", []);
```
