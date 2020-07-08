# odin-unittest
Unit testing library/framework for the Odin programming language
\
The package name ounit was chosen to make it unlikely to collide with anything.
The original name was test but I decided it was too common.
\
Failed tests will be printed out to the console.
This is done to make sure all tests run for a given package and why they are not simply asserted.
\
There are two ways to use this library.
You may use the test procs directly:
```odin
package foo

import test "ounit"

bar :: proc() {
	test.is_equal("hi", "ho"); // Will fail
	test.is_equal("hellope", "hellope"); // Will succeed
}
```
\
Alternatively you may use the provided meta attributes to annotate which procs should be called in what order and how.
Similar to other popular unit testing libraries the available attributes are:
* @before_each  (Proc should be run before each proc annotated with @test)
* @before_all   (Proc should be run once before all the others)
* @after_each   (Proc should be run after each proc annotated with @test)
* @after_all    (Proc should be run once after all the others)
* @test         (Proc containing your tests)
\
This requires preprocessing due to the custom attributes.
Check out the full example within the example folder to get an idea on how to use it.
At the moment the preprocessing creates a new odin file with the generated main proc.
So *foo.odin* -> *foo_generated.odin*.
\
The flag ``-ignore-unknown-attributes`` is needed to prevent the compiler from producing an error due to the custom attributes.
\
The meta functionality is achieved by using a modified version of my [AST printer](https://github.com/zhibog/odin-ast-printer "AST printer")