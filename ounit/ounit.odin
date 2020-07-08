package ounit

import "core:fmt"

// Unit testing for the Odin programming language
// Contains procs for checking of equality / non-equaility 
// as well as checking bools and checking for nil / non-nil.

///////////////////////////////////////////////
// Equal
///////////////////////////////////////////////
is_equal :: proc {  
    test_equal_string, test_equal_cstring,
    test_equal_int, test_equal_uint, test_equal_rune,
    test_equal_u8, test_equal_u16, test_equal_u32, test_equal_u64, test_equal_u128,
    test_equal_i8, test_equal_i16, test_equal_i32, test_equal_i64, test_equal_i128,
    test_equal_f32, test_equal_f64,
    test_equal_u16le, test_equal_u32le, test_equal_u64le, test_equal_u128le,
    test_equal_i16le, test_equal_i32le, test_equal_i64le, test_equal_i128le,
    test_equal_u16be, test_equal_u32be, test_equal_u64be, test_equal_u128be,
    test_equal_i16be, test_equal_i32be, test_equal_i64be, test_equal_i128be,
    test_equal_complex64, test_equal_complex128,
    test_equal_bool,
};



@private test_equal_string :: inline proc(expected, actual: string, loc := #caller_location)   do equal(expected == actual, expected, actual, loc);
@private test_equal_cstring :: inline proc(expected, actual: cstring, loc := #caller_location) do equal(expected == actual, expected, actual, loc);

@private test_equal_int    :: inline proc(expected, actual: int, loc := #caller_location)      do equal(expected == actual, expected, actual, loc);
@private test_equal_uint   :: inline proc(expected, actual: uint, loc := #caller_location)     do equal(expected == actual, expected, actual, loc);
@private test_equal_rune   :: inline proc(expected, actual: rune, loc := #caller_location)     do equal(expected == actual, expected, actual, loc);

@private test_equal_u8     :: inline proc(expected, actual: u8, loc := #caller_location)       do equal(expected == actual, expected, actual, loc);
@private test_equal_u16    :: inline proc(expected, actual: u16, loc := #caller_location)      do equal(expected == actual, expected, actual, loc);
@private test_equal_u32    :: inline proc(expected, actual: u32, loc := #caller_location)      do equal(expected == actual, expected, actual, loc);
@private test_equal_u64    :: inline proc(expected, actual: u64, loc := #caller_location)      do equal(expected == actual, expected, actual, loc);
@private test_equal_u128   :: inline proc(expected, actual: u128, loc := #caller_location)     do equal(expected == actual, expected, actual, loc);

@private test_equal_i8     :: inline proc(expected, actual: i8, loc := #caller_location)       do equal(expected == actual, expected, actual, loc);
@private test_equal_i16    :: inline proc(expected, actual: i16, loc := #caller_location)      do equal(expected == actual, expected, actual, loc);
@private test_equal_i32    :: inline proc(expected, actual: i32, loc := #caller_location)      do equal(expected == actual, expected, actual, loc);
@private test_equal_i64    :: inline proc(expected, actual: i64, loc := #caller_location)      do equal(expected == actual, expected, actual, loc);
@private test_equal_i128   :: inline proc(expected, actual: i128, loc := #caller_location)     do equal(expected == actual, expected, actual, loc);

@private test_equal_f32    :: inline proc(expected, actual: f32, loc := #caller_location)      do equal(expected == actual, expected, actual, loc);
@private test_equal_f64    :: inline proc(expected, actual: f64, loc := #caller_location)      do equal(expected == actual, expected, actual, loc);

@private test_equal_u16le  :: inline proc(expected, actual: u16le, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_u32le  :: inline proc(expected, actual: u32le, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_u64le  :: inline proc(expected, actual: u64le, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_u128le :: inline proc(expected, actual: u128le, loc := #caller_location)   do equal(expected == actual, expected, actual, loc);

@private test_equal_i16le  :: inline proc(expected, actual: i16le, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_i32le  :: inline proc(expected, actual: i32le, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_i64le  :: inline proc(expected, actual: i64le, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_i128le :: inline proc(expected, actual: i128le, loc := #caller_location)   do equal(expected == actual, expected, actual, loc);

@private test_equal_u16be  :: inline proc(expected, actual: u16be, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_u32be  :: inline proc(expected, actual: u32be, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_u64be  :: inline proc(expected, actual: u64be, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_u128be :: inline proc(expected, actual: u128be, loc := #caller_location)   do equal(expected == actual, expected, actual, loc);

@private test_equal_i16be  :: inline proc(expected, actual: i16be, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_i32be  :: inline proc(expected, actual: i32be, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_i64be  :: inline proc(expected, actual: i64be, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_i128be :: inline proc(expected, actual: i128be, loc := #caller_location)   do equal(expected == actual, expected, actual, loc);

@private test_equal_complex64  :: inline proc(expected, actual: complex64, loc := #caller_location)    do equal(expected == actual, expected, actual, loc);
@private test_equal_complex128 :: inline proc(expected, actual: complex128, loc := #caller_location)   do equal(expected == actual, expected, actual, loc);

@private test_equal_bool :: inline proc(expected, actual: bool, loc := #caller_location) do equal(expected != actual, expected, actual, loc);

///////////////////////////////////////////////
// Not equal
///////////////////////////////////////////////
is_not_equal :: proc {  
    test_not_equal_string, test_not_equal_cstring,
    test_not_equal_int, test_not_equal_uint, test_not_equal_rune,
    test_not_equal_u8, test_not_equal_u16, test_not_equal_u32, test_not_equal_u64, test_not_equal_u128,
    test_not_equal_i8, test_not_equal_i16, test_not_equal_i32, test_not_equal_i64, test_not_equal_i128,
    test_not_equal_f32, test_not_equal_f64,
    test_not_equal_u16le, test_not_equal_u32le, test_not_equal_u64le, test_not_equal_u128le,
    test_not_equal_i16le, test_not_equal_i32le, test_not_equal_i64le, test_not_equal_i128le,
    test_not_equal_u16be, test_not_equal_u32be, test_not_equal_u64be, test_not_equal_u128be,
    test_not_equal_i16be, test_not_equal_i32be, test_not_equal_i64be, test_not_equal_i128be,
    test_not_equal_complex64, test_not_equal_complex128,
    test_not_equal_bool,
};

@private test_not_equal_string  :: inline proc(expected, actual: string, loc := #caller_location)  do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_cstring :: inline proc(expected, actual: cstring, loc := #caller_location) do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_int    :: inline proc(expected, actual: int, loc := #caller_location)      do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_uint   :: inline proc(expected, actual: uint, loc := #caller_location)     do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_rune   :: inline proc(expected, actual: rune, loc := #caller_location)     do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_u8     :: inline proc(expected, actual: u8, loc := #caller_location)       do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u16    :: inline proc(expected, actual: u16, loc := #caller_location)      do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u32    :: inline proc(expected, actual: u32, loc := #caller_location)      do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u64    :: inline proc(expected, actual: u64, loc := #caller_location)      do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u128   :: inline proc(expected, actual: u128, loc := #caller_location)     do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_i8     :: inline proc(expected, actual: i8, loc := #caller_location)       do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i16    :: inline proc(expected, actual: i16, loc := #caller_location)      do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i32    :: inline proc(expected, actual: i32, loc := #caller_location)      do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i64    :: inline proc(expected, actual: i64, loc := #caller_location)      do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i128   :: inline proc(expected, actual: i128, loc := #caller_location)     do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_f32    :: inline proc(expected, actual: f32, loc := #caller_location)      do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_f64    :: inline proc(expected, actual: f64, loc := #caller_location)      do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_u16le  :: inline proc(expected, actual: u16le, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u32le  :: inline proc(expected, actual: u32le, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u64le  :: inline proc(expected, actual: u64le, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u128le :: inline proc(expected, actual: u128le, loc := #caller_location)   do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_i16le  :: inline proc(expected, actual: i16le, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i32le  :: inline proc(expected, actual: i32le, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i64le  :: inline proc(expected, actual: i64le, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i128le :: inline proc(expected, actual: i128le, loc := #caller_location)   do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_u16be  :: inline proc(expected, actual: u16be, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u32be  :: inline proc(expected, actual: u32be, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u64be  :: inline proc(expected, actual: u64be, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_u128be :: inline proc(expected, actual: u128be, loc := #caller_location)   do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_i16be  :: inline proc(expected, actual: i16be, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i32be  :: inline proc(expected, actual: i32be, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i64be  :: inline proc(expected, actual: i64be, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_i128be :: inline proc(expected, actual: i128be, loc := #caller_location)   do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_complex64  :: inline proc(expected, actual: complex64, loc := #caller_location)    do not_equal(expected != actual, expected, actual, loc);
@private test_not_equal_complex128 :: inline proc(expected, actual: complex128, loc := #caller_location)   do not_equal(expected != actual, expected, actual, loc);

@private test_not_equal_bool :: inline proc(expected, actual: bool, loc := #caller_location) do not_equal(expected != actual, expected, actual, loc);

///////////////////////////////////////////////
// True / false
///////////////////////////////////////////////

is_true  :: inline proc(condition: bool, loc := #caller_location)  do if !condition do fmt.printf("%v %v:%v Expected: \"true\" Actual: \"false\"\n", loc.file_path, loc.line, loc.column);
is_false :: inline proc(condition: bool, loc := #caller_location)  do if condition  do fmt.printf("%v %v:%v Expected: \"false\" Actual: \"true\"\n", loc.file_path, loc.line, loc.column);

///////////////////////////////////////////////
// Nil / not-nil
///////////////////////////////////////////////

is_nil     :: inline proc(t: $T, loc := #caller_location)  do if t != nil  do fmt.printf("%v %v:%v Expected: \"nil\" Actual: \"%v\"\n", loc.file_path, loc.line, loc.column, t);
is_not_nil :: inline proc(t: $T, loc := #caller_location)  do if t == nil  do fmt.printf("%v %v:%v Expected not: \"nil\" Actual: \"%v\"\n", loc.file_path, loc.line, loc.column, t);

///////////////////////////////////////////////
// Utility procs
///////////////////////////////////////////////

@private equal :: inline proc(condition: bool, expected, actual: any ,loc := #caller_location) {
    if !condition do fmt.printf("%v %v:%v Expected: \"%v\" Actual: \"%v\"\n",loc.file_path, loc.line, loc.column, expected, actual);
}

@private not_equal :: inline proc(condition: bool, expected, actual: any ,loc := #caller_location) {
    if !condition do fmt.printf("%v %v:%v Expected not: \"%v\" Actual: \"%v\"\n",loc.file_path, loc.line, loc.column, expected, actual);
}