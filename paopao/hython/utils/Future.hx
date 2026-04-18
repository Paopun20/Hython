package paopao.hython.utils;

class Future<T> {
    var done = false;
    var value:T;
    var callbacks:Array<T->Void> = [];

    public function resolve(v:T) {
        done = true;
        value = v;
        for (cb in callbacks) cb(v);
    }

    public function then(cb:T->Void) {
        if (done) cb(value);
        else callbacks.push(cb);
    }
}