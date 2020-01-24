package meta_example

Foo :: struct {
    bar: string,
    baz: int,
    buz: [dynamic]byte,
};

add_buz :: proc(f: ^Foo, b: byte) -> bool {
    if b != 0 {
        append(&f.buz, b);
        return true;
    } else {
        return false;
    }
}
