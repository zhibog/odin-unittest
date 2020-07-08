package test_example

import test "../../ounit"

// @note(zh): Example useage of the unit tests.
// Run with: odin run test_example.odin

main :: proc() {

    // strings
    str1 := "Hello";
    str2 := "Hello";
    str3 := "Hellope";
    str4 := cstring("hello");
    str5 := cstring("hellope");

    test.is_equal(str1, str2);      // Will succeed
    test.is_equal(str1, str3);      // Will fail
    test.is_not_equal(str1, str3);  // Will succeed
    test.is_not_equal(str1, str2);  // Will fail
    test.is_equal(str4, str5);      // Will fail
    test.is_not_equal(str4, str5);  // Will succeed

    // numbers
    num1 := 5;
    num2 := 6;
    num3 := u32be(5);
    num4 := u32be(5);
    num5 := u32be(4);

    test.is_equal(num1, num2);      // Will fail
    test.is_not_equal(num1, num2);  // Will succeed
    test.is_equal(num3, num3);      // Will succeed
    test.is_not_equal(num3, num4);  // Will fail
    test.is_equal(num3, num5);      // Will fail
    test.is_not_equal(num3, num5);  // Will succeed

    // nil, not nil
    A :: union {
        uint, u32,
    };

    a: A = nil;
    b: A = u32(32);

    test.is_nil(a);                 // Will succeed
    test.is_nil(b);                 // Will fail
    test.is_not_nil(a);             // Will fail
    test.is_not_nil(b);             // Will succeed

    // boolean
    bool1 := true;
    bool2 := false;

    test.is_true(bool1);            // Will succeed
    test.is_true(bool2);            // Will fail
    test.is_false(bool1);           // Will fail
    test.is_false(bool2);           // Will succeed
    test.is_true(1 == 1);           // Will succeed
    test.is_false(1 == 2);          // Will succeed
}