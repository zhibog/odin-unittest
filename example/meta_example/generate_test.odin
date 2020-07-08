package generate_test

import "core:strings"
import "../../ounit/meta"

main :: proc() {
	sb := strings.make_builder();
	defer strings.destroy_builder(&sb);
	meta.generate("tests/m_test.odin", &sb);
}