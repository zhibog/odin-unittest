package ast_printer_test

import "core:fmt"

aa :: inline proc "contextless"() -> (int, int) {
    //a, b: int;
    a, b := 5, d;
    c, d :: 10, 12;
    
    return a, b;
}

Vec2 :: struct {
    x, y: int,
};

add :: proc(a, b: Vec2) -> (res: Vec2) {
    res = {a.x+b.x, a.y+b.y};
    return;
}

main :: proc() {
    z, cc: int;
    cc, z = aa();
}