package m_test

import test "../../../ounit"
import "../m"

f: m.Foo;

// This will be processed into a file which includes a main proc looking like this:
//  main :: proc() {
//      init();
//      test_init();
//      init();
//      test_appending();
//  }

@before_each
init :: proc() {
    f.bar = "Hello";
    f.baz = 5;
    f.buz = nil;
}

@test
test_init :: proc() {
    test.is_equal("Hello", f.bar);
    test.is_equal(5, f.baz);
    test.is_true(len(f.buz) == 0);
}

@test
test_appending :: proc() {
    test.is_true(len(f.buz) == 0);
    test.is_true(m.add_buz(&f, 1));
    test.is_true(m.add_buz(&f, 2));
    test.is_false(m.add_buz(&f, 0));
    test.is_false(len(f.buz) == 2);  // Will fail
}