package paopao.hython.library;

import haxe.Json.Json;

class PyJson {
    public static function dumps(value:Dynamic):String {
        return Json.stringify(value);
    }

    public static function loads(jsonString:String):Dynamic {
        return Json.parse(jsonString);
    }
}