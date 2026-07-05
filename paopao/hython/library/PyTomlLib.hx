package paopao.hython.library;

import paopao.toml.Toml;

/*
like python tomllib module, this class provides a way to parse TOML files and convert them into Haxe data structures. It includes functions for reading TOML files, parsing the content, and accessing the resulting data in a structured manner.
*/
class PyTomlLib {
    public static function load(filePath:String):Dynamic {
        var tomlContent:String = Sys.readFile(filePath);
        var parsedData:Dynamic = Toml.parse(tomlContent);
        return parsedData;
    }

    public static function loads(tomlString:String):Dynamic {
        var parsedData:Dynamic = Toml.parse(tomlString);
        return parsedData;
    }
}