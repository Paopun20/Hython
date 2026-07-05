class TestCrashIsolate {
    static function main() {
        Sys.println("Before Interpreter");
        var interp = new paopao.hython.Interpreter("<test>");
        Sys.println("After Interpreter: " + interp.filename);
    }
}
