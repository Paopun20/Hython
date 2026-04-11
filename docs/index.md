# Home

Hython is a Python interpreter written in Haxe. It allows you to run Python code directly from the command line or within your Haxe projects.

## Features

- **Lightweight**: Small memory footprint and fast execution speed (~4x faster than CPython in cpp target)
- **Easy Integration**: Easily integrates with Haxe/Haxeflixel projects
- **Own Runtime System**: Custom runtime for efficiency

## Installation

```bash
haxelib install hython
```

Dev Build:

```bash
haxelib git hython https://github.com/Paopun20/hython.git dev
```

## Quick Start

```haxe
import paopao.hython.Parser;
import paopao.hython.Interp;

var parser = new Parser();
var expr = parser.parseString("print('Hello, World!')");
var interp = new Interp();
interp.execute(expr);
```

## Documentation

- [Usage Guide](usage.md) - Detailed usage examples
- [API Reference](api.md) - API documentation
- [Features](features.md) - Supported Python features
