package paopao.hython.library;

import sys.FileSystem;

class PyOS {
    public static function getcwd():String {
        return Sys.getCwd();
    }

    public static function chdir(path:String):Void {
        Sys.setCwd(FileSystem.absolutePath(path));
    }

    public static function listdir(path:String):Array<String> {
        return FileSystem.readDirectory(FileSystem.absolutePath(path));
    }

    public static function mkdir(path:String):Void {
        FileSystem.createDirectory(FileSystem.absolutePath(path));
    }

    public static function rmdir(path:String):Void {
        FileSystem.removeDirectory(FileSystem.absolutePath(path));
    }

    public static function remove(path:String):Void {
        if (FileSystem.isDirectory(path)) {
            Sys.rmdir(path);
        } else {
            Sys.remove(path);
        }
    }

    public static function exists(path:String):Bool {
        return FileSystem.exists(path);
    }

    public static function isdir(path:String):Bool {
        return FileSystem.isDirectory(path);
    }

    public static function isfile(path:String):Bool {
        return !FileSystem.isDirectory(path);
    }

    public static function getenv(varName:String):Null<String> {
        return Sys.getEnv(varName);
    }

    public static function setenv(varName:String, value:String):Void {
        Sys.putEnv(varName, value);
    }

    public static function system(command:String):Int {
        return Sys.command(command);
    }
}