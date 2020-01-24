package meta_test

/*******************
    Will result in a main proc being created that should look like this:
        main :: proc() {
            init();
            test_init();
            init();
            test_appending();
        }

        @before_each literally means before each call of a @test proc & vice versa with @after_each

        @before_all and @after_all only run once

        Maybe I can find some better terms for it tho
 *******************/

import "../test"
import m "meta_example"

f : m.Foo;

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
    test.is_true(len(f.buz) == 2);
}