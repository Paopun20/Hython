class TestLibraryInit {
    static function main() {
        Sys.println("Before Library check");
        trace(paopao.hython.Library.exists("os"));
        Sys.println("After Library check");
    }
}
