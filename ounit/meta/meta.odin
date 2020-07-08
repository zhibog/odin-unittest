package meta

import "core:odin/ast"
import "core:odin/parser"
import "core:odin/tokenizer"
import "core:os"
import "core:fmt"
import "core:strings"

Meta :: struct {
    kind: MetaKind,
    text: string,
};

MetaKind :: enum int {
    BeforeAll,
    BeforeEach,
    AfterAll,
    AfterEach,
    Test,
    COUNT,
};

meta_kinds := [MetaKind.COUNT]string {
    "before_all",
    "before_each",
    "after_all",
    "after_each",
    "test",
};

meta: [dynamic]Meta;
curr_index: int = -1;
found_attr: bool = false;

generate :: proc(file_path: string, sb: ^strings.Builder) -> bool {
    print_ast(file_path, sb);
    generate_main(sb);
    return write_file_raw(file_path, transmute([]byte)(strings.to_string(sb^)));
}

generate_main :: proc(sb: ^strings.Builder) {
    strings.write_string(sb, "\nmain :: proc() {\n");
    bf_each: Meta;
    bf_all:  Meta;
    af_each: Meta;
    af_all:  Meta;
    for v in meta {
        if v.kind == MetaKind.BeforeEach do bf_each = v;
        if v.kind == MetaKind.AfterEach  do af_each = v;
        if v.kind == MetaKind.BeforeAll  do bf_all  = v;
        if v.kind == MetaKind.AfterAll   do af_all  = v;
    } 
    if bf_all.kind == MetaKind.BeforeAll && bf_all.text != "" {
        strings.write_string(sb, "   ");
        strings.write_string(sb, bf_all.text);
        strings.write_string(sb, "();\n");
    }
    for v in meta {
        if v.kind != MetaKind.BeforeEach && bf_each.text != "" {
            strings.write_string(sb, "   ");
            strings.write_string(sb, bf_each.text);
            strings.write_string(sb, "();\n");
        }
        if v.kind == MetaKind.Test && v.text != "" {
            strings.write_string(sb, "   ");
            strings.write_string(sb, v.text);
            strings.write_string(sb, "();\n");
        }
        if v.kind != MetaKind.AfterEach && af_each.text != "" {
            strings.write_string(sb, "   ");
            strings.write_string(sb, af_each.text);
            strings.write_string(sb, "();\n");
        }
    }
    if af_all.kind == MetaKind.AfterAll && af_all.text != "" {
        strings.write_string(sb, "   ");
        strings.write_string(sb, af_all.text);
        strings.write_string(sb, "();\n");
    }
    strings.write_string(sb, "}\n");
}

populate_meta_info :: proc(i: ^ast.Ident, check_attr: bool) -> bool{
    if check_attr {
        switch i.name {
            case meta_kinds[MetaKind.BeforeEach]: {
                append(&meta, Meta{kind = MetaKind.BeforeEach});
                found_attr, curr_index = true, curr_index + 1;
            }
            case meta_kinds[MetaKind.AfterEach]: {
                append(&meta, Meta{kind = MetaKind.AfterEach});
                found_attr, curr_index = true, curr_index + 1;
            }
            case meta_kinds[MetaKind.BeforeAll]: {
                append(&meta, Meta{kind = MetaKind.BeforeAll});
                found_attr, curr_index = true, curr_index + 1;
            }
            case meta_kinds[MetaKind.AfterAll]: {
                append(&meta, Meta{kind = MetaKind.AfterAll});
                found_attr, curr_index = true, curr_index + 1;
            }
            case meta_kinds[MetaKind.Test]: {
                append(&meta, Meta{kind = MetaKind.Test});
                found_attr, curr_index = true, curr_index + 1;
            }
        }
    } else do if found_attr do meta[curr_index].text, found_attr = i.name, false;
    return found_attr;
}

write_file_raw :: proc(path: string, data: []byte) -> bool {
    p, _ := strings.replace(path, ".odin", "_generated.odin", len(path));
    file, err := os.open(p, os.O_RDWR | os.O_CREATE | os.O_TRUNC);
    if err != os.ERROR_NONE do return false;
    defer os.close(file);

    if _, err := os.write(file, data); err != os.ERROR_NONE do return false;
    return true;
}

print_ast :: proc(file_path: string, sb: ^strings.Builder) {
    if data, ok := os.read_entire_file(file_path); ok {
        p := parser.Parser{};
        f := ast.File{
                src = data, 
                fullpath = file_path,
        };

        if res := parser.parse_file(&p, &f); res {
            root := p.file;
            indent := 0;

            strings.write_string(sb, "package ");
            strings.write_string(sb, root.pkg_name);
            strings.write_string(sb, "\n\n");
            
            length := len(root.decls);
            for v, i in root.decls {
                switch s in &v.derived {
                    case ast.Import_Decl:   generate_import_decl(sb, &s, indent);
                    case ast.Value_Decl:    generate_value_decl(sb, &s, indent);
                    case ast.When_Stmt:     generate_when_stmt(sb, &s, indent);
                    case: fmt.println("root.decls\n", s^);
                }
                if i < length do strings.write_string(sb, "\n");
            }
        }
    } else {
        // @todo(zh): write error
    }
}

///////////////////////////////////////////////
// Declarations
///////////////////////////////////////////////

generate_import_decl :: proc(sb: ^strings.Builder, decl: ^ast.Import_Decl, indent: int) {
    if decl.is_using do strings.write_string(sb, "using ");
    strings.write_string(sb, decl.import_tok.text);
    if decl.name.text != "" {
        strings.write_string(sb, " ");
        strings.write_string(sb, decl.name.text);
    }
    strings.write_string(sb, " ");   
    strings.write_string(sb, decl.relpath.text);
}

generate_foreign_block_decl :: proc(sb: ^strings.Builder, r: ^ast.Foreign_Block_Decl, indent: int) {
    strings.write_string(sb, r.tok.text);
    strings.write_string(sb, " ");
    switch s in &r.foreign_library.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case: fmt.println("generate_foreign_block_decl foreign_library\n", s^);
    }
    strings.write_string(sb, " {\n");
    switch s in &r.body.derived {
        case ast.Block_Stmt: generate_block_stmt(sb, &s, indent);
        case: fmt.println("generate_foreign_block_decl body\n", s^);
    }
    strings.write_string(sb, "    }\n");
}

generate_foreign_import_decl :: proc(sb: ^strings.Builder, r: ^ast.Foreign_Import_Decl, indent: int) {
    strings.write_string(sb, r.foreign_tok.text);
    strings.write_string(sb, " ");
    strings.write_string(sb, r.import_tok.text);
    strings.write_string(sb, " ");
    if r.name != nil {
        switch s in &r.name.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_foreign_import_decl\n", s^);
        }
    }
    if len(r.fullpaths) > 0 {
        strings.write_string(sb, " ");
        strings.write_string(sb, r.fullpaths[0]);
    }
}

generate_value_decl :: proc(sb: ^strings.Builder, decl: ^ast.Value_Decl, indent: int) {
    if decl.is_using do strings.write_string(sb, "using ");
    for v, _ in decl.attributes {
        switch s in &v.derived {
            case ast.Attribute: generate_attribute(sb, &s, indent);
            case: fmt.println("generate_value_decl attributes\n", s^);
        }
    }    
    names_length := len(decl.names);
    for v, i in decl.names {
        switch s in &v.derived {
            case ast.Ident: {
                generate_ident(sb, &s, indent, false);
                if names_length > 1 && i < names_length - 1 do strings.write_string(sb, ", ");
            }
            case: fmt.println("generate_value_decl names\n", s^);
        }
    }
    values_length := len(decl.values);
    if decl.type != nil {
        strings.write_string(sb, ": ");
        switch s in &decl.type.derived {
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case ast.Ident:         generate_ident(sb, &s, indent, false);
            case ast.Array_Type:    generate_array_type(sb, &s, indent);
            case ast.Pointer_Type:  generate_pointer_type(sb, &s, indent);
            case ast.Index_Expr:    generate_index_expr(sb, &s, indent);
            case ast.Bit_Set_Type:  generate_bit_set_type(sb, &s, indent);
            case ast.Dynamic_Array_Type: generate_dynamic_array_type(sb, &s, indent);
            case ast.Call_Expr:     generate_call_expr(sb, &s, indent);
            case ast.Union_Type:    generate_union_type(sb, &s, indent);
            case: fmt.println("generate_value_decl type\n", s^);
        }
        if decl.is_mutable {
            if values_length == 0 do strings.write_string(sb, ";");
            else do strings.write_string(sb, " = ");
        } 
        else do strings.write_string(sb, ": ");
        
    }

    print_separator :: inline proc(decl_type: ^ast.Expr, is_mutable: bool, sb: ^strings.Builder) {
        if decl_type == nil {
            if is_mutable do strings.write_string(sb, " := ");
            else if !is_mutable {
                if decl_type == nil do strings.write_string(sb, " :: ");
            } 
        }
    }

    for v, i in decl.values {
        switch s in &v.derived {
            case ast.Proc_Lit: {
                generate_proc_lit(sb, &s, indent);
            }
            case ast.Basic_Lit: {
                if i == 0 {
                    print_separator(decl.type, decl.is_mutable, sb);
                }
                generate_basic_lit(sb, &s, indent);
                if values_length > 1 && i < values_length - 1 do strings.write_string(sb, ", ");
                if i == values_length - 1 do strings.write_string(sb, ";");
            }
            case ast.Ident: {
                if i == 0 {
                    print_separator(decl.type, decl.is_mutable, sb);
                }
                generate_ident(sb, &s, indent, false);
                if values_length > 1 && i < values_length - 1 do strings.write_string(sb, ", ");
                if i == values_length - 1 do strings.write_string(sb, ";");
            }
            case ast.Struct_Type: {
                generate_struct_type(sb, &s, indent);
            }
            case ast.Union_Type: generate_union_type(sb, &s, indent + 1);
            case ast.Call_Expr: {
                strings.write_string(sb, " := ");
                generate_call_expr(sb, &s, indent);
                strings.write_string(sb, ";");
            }
            case ast.Paren_Expr:  {
                print_separator(decl.type, decl.is_mutable, sb);
                generate_paren_expr(sb, &s, indent);
                strings.write_string(sb, "; ");
            }
            case ast.Binary_Expr: {
                if decl.type == nil {
                    if decl.is_mutable do strings.write_string(sb, " := ");
                    else if !decl.is_mutable {
                        if decl.type == nil do strings.write_string(sb, " :: ");
                    } 
                }
                generate_binary_expr(sb, &s, indent);
                strings.write_string(sb, "; ");
            }
            case ast.Slice_Expr: {
                print_separator(decl.type, decl.is_mutable, sb);
                generate_slice_expr(sb, &s, indent);
                strings.write_string(sb, "; ");
            }
            case ast.Comp_Lit: {
                print_separator(decl.type, decl.is_mutable, sb);
                generate_comp_lit(sb, &s, indent);
                strings.write_string(sb, ";\n");
            }
            case ast.Proc_Group: {
                strings.write_string(sb, " :: ");
                generate_proc_group(sb, &s, indent);
                strings.write_string(sb, ";\n");
            }
            case ast.Selector_Expr: {
                print_separator(decl.type, decl.is_mutable, sb);
                generate_selector_expr(sb, &s, indent);
                strings.write_string(sb, ";\n");
            }
            case ast.Deref_Expr: {
                print_separator(decl.type, decl.is_mutable, sb);
                generate_deref_expr(sb, &s, indent);
                strings.write_string(sb, ";");
            }
            case ast.Proc_Type: {
                strings.write_string(sb, " :: ");
                generate_proc_type(sb, &s, indent);
            }
            case ast.Block_Stmt: {
                if s.uses_do {
                    strings.write_string(sb, " do ");
                    generate_block_stmt(sb, &s, indent);
                } else {
                    strings.write_string(sb, " {\n    ");
                    generate_block_stmt(sb, &s, indent);
                    strings.write_string(sb, "    }");
                }
            }
            case ast.Enum_Type: {
                generate_enum_type(sb, &s, indent + 1);
            }
            case ast.Unary_Expr: {
                if i == 0 do print_separator(decl.type, decl.is_mutable, sb);
                generate_unary_expr(sb, &s, indent);
                if values_length > 1 && i < values_length - 1 do strings.write_string(sb, ", ");
                if i == values_length - 1 do strings.write_string(sb, ";");
            }
            case ast.Distinct_Type: {
                strings.write_string(sb, " :: ");
                generate_distinct_type(sb, &s, indent);
            }
            case ast.Bit_Set_Type: {
                strings.write_string(sb, " :: ");
                generate_bit_set_type(sb, &s, indent);
                strings.write_string(sb, ";");
            }
            case ast.Index_Expr: {
                if i == 0 {
                    print_separator(decl.type, decl.is_mutable, sb);
                }
                generate_index_expr(sb, &s, indent);
                if values_length > 1 && i < values_length - 1 do strings.write_string(sb, ", ");
                if i == values_length - 1 do strings.write_string(sb, ";");
            }
            case ast.Type_Cast: {
                if i == 0 {
                    print_separator(decl.type, decl.is_mutable, sb);
                }
                generate_type_cast(sb, &s, indent);
                if values_length > 1 && i < values_length - 1 do strings.write_string(sb, ", ");
                if i == values_length - 1 do strings.write_string(sb, ";");
            }
            case ast.Undef: {
                generate_undef(sb, &s, indent);
                if values_length > 1 && i < values_length - 1 do strings.write_string(sb, ", ");
                if i == values_length - 1 do strings.write_string(sb, ";");
            }
            case ast.Bit_Field_Type: {
                strings.write_string(sb, " :: ");
                generate_bit_field_type(sb, &s, indent);
                strings.write_string(sb, ";");
            }
            case: fmt.println("generate_value_decl values\n", s^);
        }
    }
}

///////////////////////////////////////////////
// Types
///////////////////////////////////////////////

generate_distinct_type :: proc(sb: ^strings.Builder, a: ^ast.Distinct_Type, indent: int) {
    strings.write_string(sb, "distinct ");
    switch s in &a.type.derived {
        case ast.Bit_Set_Type: generate_bit_set_type(sb, &s, indent);
        case ast.Array_Type:   generate_array_type(sb, &s, indent);
        case ast.Ident:        generate_ident(sb, &s, indent, false);
        case: fmt.println("generate_distinct_type type\n", s^);
    }
    strings.write_string(sb, ";");
}

generate_array_type :: proc(sb: ^strings.Builder, a: ^ast.Array_Type, indent: int) {
    strings.write_string(sb, "[");
    if a.len != nil {
        switch s in &a.len.derived {
            case ast.Basic_Lit: generate_basic_lit(sb, &s, indent);
            case ast.Unary_Expr: generate_unary_expr(sb, &s, indent);
            case ast.Ident:     generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_array_type len\n", s^);
        }
    }
    strings.write_string(sb, "]");
    switch s in &a.elem.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
        case ast.Poly_Type: generate_poly_type(sb, &s, indent);
        case: fmt.println("generate_array_type elem\n", s^);
    }
}

generate_enum_type :: proc(sb: ^strings.Builder, st: ^ast.Enum_Type, indent: int) {
    strings.write_string(sb, " :: enum");
    if st.base_type != nil {
        switch s in &st.base_type.derived {
            case ast.Ident: {
                strings.write_string(sb, " ");
                generate_ident(sb, &s, indent, false);
            }
            case: fmt.println("generate_enum_type base_type\n", s^);
        }
    }
    strings.write_string(sb, " {\n");
    for v, _ in st.fields {
        for in 0..<indent do strings.write_string(sb, "    ");
        switch s in &v.derived {
            case ast.Ident: {
                generate_ident(sb, &s, indent, false);
                strings.write_string(sb, ",\n");
            }
            case: fmt.println("generate_enum_type fields\n", s^);
        }
    }
    strings.write_string(sb, "};\n");
}

generate_struct_type :: proc(sb: ^strings.Builder, st: ^ast.Struct_Type, indent: int) {
    switch s in &st.fields.derived {
        case ast.Field_List: {
            strings.write_string(sb, " :: struct");
            if st.align != nil {
                strings.write_string(sb, " #align ");
                switch s in &st.align.derived {
                    case ast.Basic_Lit: generate_basic_lit(sb, &s, indent);
                    case: fmt.println("generate_struct_type align\n", s^);
                }
                strings.write_string(sb, " ");
            }
            if st.is_packed     do strings.write_string(sb, " #packed");
            if st.is_raw_union  do strings.write_string(sb, " #raw_union");
            strings.write_string(sb, " {\n");
            generate_field_list(sb, &s, indent + 1);
        }
        case: fmt.println("generate_struct_type\n", s^);
    }
    strings.write_string(sb, "\n};\n");
}

// @todo(zh): one ; too much from here
generate_union_type :: proc(sb: ^strings.Builder, u: ^ast.Union_Type, indent: int) {
    strings.write_string(sb, " :: union");
    if u.poly_params != nil {
        strings.write_string(sb, "(");
        switch s in &u.poly_params.derived {
            case ast.Field_List: generate_field_list(sb, &s, indent);
            case: fmt.println("generate_union_type poly_params\n", s^);
        }
        strings.write_string(sb, ")");
    }
    if u.is_maybe {
        strings.write_string(sb, " #maybe");
    }
    strings.write_string(sb, " {\n");
    length := len(u.variants);
    for v, _ in u.variants {
        for in 0..<indent do strings.write_string(sb, "    ");
        switch s in &v.derived {
            case ast.Ident: {
                generate_ident(sb, &s, indent, false);
                if length > 1 do strings.write_string(sb, ",\n");
            }
            case: fmt.println("generate_union_type variants\n", s^);
        }
    }
    strings.write_string(sb, "};");
}

generate_typeid_type :: proc(sb: ^strings.Builder, t: ^ast.Typeid_Type, indent: int) {
    strings.write_string(sb, "typeid");
    if t.specialization != nil {
        switch s in &t.specialization.derived {
            case ast.Poly_Type: {
                strings.write_string(sb, "/");
                generate_poly_type(sb, &s, indent);
            }
            case: fmt.println("generate_typeid_type\n", s^);
        }
    }
}

generate_proc_type :: proc(sb: ^strings.Builder, p: ^ast.Proc_Type, indent: int) {
    #partial switch p.tok.kind {
        case tokenizer.Token_Kind.Proc: {
            generate_value(sb, &p.tok, indent);
        }
        case: fmt.println("generate_proc_type tok\n", p.tok.kind);
    }
    switch p.calling_convention {
        case .Invalid:
        case .Odin:
        case .Contextless: strings.write_string(sb, " \"contextless\" ");
        case .C_Decl: strings.write_string(sb, " \"c\" ");
        case .Std_Call: strings.write_string(sb, " \"std\" ");
        case .Fast_Call: strings.write_string(sb, " \"fast\" ");
        case .Foreign_Block_Default:
    }
    strings.write_string(sb, "(");
    params_length := len(p.params.list);
    for v, i in p.params.list {
        switch s in &v.derived {
            case ast.Field_List: generate_field_list(sb, &s, indent + 1);
            case ast.Field: {
                generate_field(sb, &s, indent);
                if params_length > 1 && i < params_length - 1 do strings.write_string(sb, ", ");
            }
            case: fmt.println("generate_proc_type params\n", s^);
        }
    }
    strings.write_string(sb, ")");
    if p.results != nil {
        strings.write_string(sb, " -> ");
        res_length := len(p.results.list) ;
        if res_length > 1 do strings.write_string(sb, "(");
        for v, i in p.results.list {
            names_length := len(v.names);
            has_name := false;
            for m, j in v.names {
                switch b in &m.derived {
                    case ast.Ident: {
                        if b.name != "" {
                            generate_ident(sb, &b, indent, false);
                            if j == names_length - 1 do strings.write_string(sb, ": ");
                            else do strings.write_string(sb, ", ");
                            has_name = true;
                        } else {
                            has_name = false;
                        }
                    }
                    case: fmt.println("generate_proc_type results names\n", b^);
                }
            }
            switch s in &v.type.derived {
                case ast.Pointer_Type: generate_pointer_type(sb, &s, indent);
                case ast.Ident:  generate_ident(sb, &s, indent, false);
                case ast.Array_Type: generate_array_type(sb, &s, indent);
                case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
                case: fmt.println("generate_proc_type results type\n", s^);
            }
            if res_length > 1 && i < res_length - 1 do strings.write_string(sb, ", ");
        }
        if res_length > 1 do strings.write_string(sb, ")");
    }
}

generate_bit_set_type :: proc(sb: ^strings.Builder, m: ^ast.Bit_Set_Type, indent: int) {
    strings.write_string(sb, "bit_set[");
    switch s in &m.elem.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case ast.Binary_Expr: generate_binary_expr(sb, &s, indent);
        case: fmt.println("generate_bit_set_type elem\n", s^);
    }
    if m.underlying != nil {
        strings.write_string(sb, "; ");
        switch s in &m.underlying.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_bit_set_type underlying\n", s^);
        }
    }
    strings.write_string(sb, "]");
}

generate_bit_field_type :: proc(sb: ^strings.Builder, st: ^ast.Bit_Field_Type, indent: int) {
    strings.write_string(sb, "bit_field ");
    if st.align != nil {
        strings.write_string(sb, " #align ");
        switch s in &st.align.derived {
            case ast.Basic_Lit: generate_basic_lit(sb, &s, indent);
            case: fmt.println("generate_struct_type align\n", s^);
        }
        strings.write_string(sb, " ");
    }
    if st.fields != nil {
        for v, i in st.fields {
            if i == 0 do strings.write_string(sb, "{");
            switch s in &v.derived {
                case ast.Field_Value: generate_field_value(sb, &s, indent, ": ");
                case: fmt.println("generate_bit_field_type fields\n", s^);
            }
            if i == len(st.fields) - 1 do strings.write_string(sb, "}");
            else do strings.write_string(sb, ", ");
        }
    } else {
        strings.write_string(sb, "{}");
    }
}

generate_map_type :: proc(sb: ^strings.Builder, m: ^ast.Map_Type, indent: int) {
    strings.write_string(sb, "map[");
    switch s in &m.key.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case: fmt.println("generate_map_type key\n", s^);
    }
    strings.write_string(sb, "]");
    switch s in &m.value.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case: fmt.println("generate_map_type value\n", s^);
    }
}

generate_dynamic_array_type :: proc(sb: ^strings.Builder, b: ^ast.Dynamic_Array_Type, indent: int) {
    strings.write_string(sb, "[dynamic]");
    if b.tag != nil {
        //@todo(zh): implement

    }
    switch s in &b.elem.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case: fmt.println("generate_dynamic_array_type elem\n", s^);
    }
}

generate_poly_type :: proc(sb: ^strings.Builder, p: ^ast.Poly_Type, indent: int) {
    switch s in &p.type.derived {
        case ast.Ident: {
            strings.write_string(sb, "$");
            generate_ident(sb, &s, indent, false);
        } 
        case: fmt.println("generate_poly_type type\n", s^);
    }
    if p.specialization != nil {
        strings.write_string(sb, "/");
        switch s in &p.specialization.derived {
            case ast.Call_Expr: generate_call_expr(sb, &s, indent);
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case ast.Array_Type: generate_array_type(sb, &s, indent);
            case: fmt.println("generate_poly_type specialization\n", s^);
        }
    }
}

generate_pointer_type :: proc(sb: ^strings.Builder, p: ^ast.Pointer_Type, indent: int) {
    strings.write_string(sb, "^");
    switch s in &p.elem.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case ast.Poly_Type: {
            generate_poly_type(sb, &s, indent);
        }
        case: fmt.println("generate_pointer_type\n", s^);
    }
}

///////////////////////////////////////////////
// Statements
///////////////////////////////////////////////

generate_block_stmt :: proc(sb: ^strings.Builder, b: ^ast.Block_Stmt, indent: int) {
    if b.label != nil {
        switch s in &b.label.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_block_stmt label\n", s^);
        }
        strings.write_string(sb, ": ");
    }
    for v, _ in b.stmts {
        if !b.uses_do {
            for in 0..<indent do strings.write_string(sb, "    ");
        }
        switch s in &v.derived {
            case ast.Assign_Stmt: {
                generate_assign_stmt(sb, &s, indent);
                strings.write_string(sb, ";");
            }
            case ast.Expr_Stmt:   generate_expr_stmt(sb, &s, indent);
            case ast.Return_Stmt: generate_return_stmt(sb, &s, indent);
            case ast.Value_Decl:  generate_value_decl(sb, &s, indent);
            case ast.If_Stmt:     generate_if_stmt(sb, &s, indent);
            case ast.When_Stmt:   generate_when_stmt(sb, &s, indent);
            case ast.For_Stmt:    generate_for_stmt(sb, &s, indent);
            case ast.Range_Stmt:  generate_range_stmt(sb, &s, indent);
            case ast.Block_Stmt:  generate_block_stmt(sb, &s, indent);
            case ast.Switch_Stmt: generate_switch_stmt(sb, &s, indent);
            case ast.Case_Clause: generate_case_clause(sb, &s, indent);
            case ast.Type_Switch_Stmt: generate_type_switch_stmt(sb, &s, indent);
            case ast.Defer_Stmt:  generate_defer_stmt(sb, &s, indent);
            case ast.Foreign_Import_Decl: generate_foreign_import_decl(sb, &s, indent);
            case ast.Foreign_Block_Decl: generate_foreign_block_decl(sb, &s, indent);
            case ast.Branch_Stmt: generate_branch_stmt(sb, &s, indent);
            case: fmt.println("generate_block_stmt stmts\n", s^);
        }
        strings.write_string(sb, "\n");
    }
    if b.label != nil do strings.write_string(sb, "    }\n");
}

generate_defer_stmt :: proc(sb: ^strings.Builder, r: ^ast.Defer_Stmt, indent: int) {
    strings.write_string(sb, "defer ");
    switch s in &r.stmt.derived {
        case ast.Expr_Stmt: generate_expr_stmt(sb, &s, indent);
        case ast.Assign_Stmt: generate_assign_stmt(sb, &s, indent);
        case ast.Block_Stmt: generate_block_stmt(sb, &s, indent);
        case ast.If_Stmt: generate_if_stmt(sb, &s, indent);
        case: fmt.println("generate_defer_stmt\n", s^);
    }
}

generate_branch_stmt :: proc(sb: ^strings.Builder, r: ^ast.Branch_Stmt, indent: int) {
    strings.write_string(sb, r.tok.text);
    strings.write_string(sb, ";");
}

generate_type_switch_stmt :: proc(sb: ^strings.Builder, r: ^ast.Type_Switch_Stmt, indent: int) {
    if r.partial {
        strings.write_string(sb, "#partial ");
    }
    if r.label != nil {
        switch s in &r.label.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_type_switch_stmt label\n", s^);
        }
        strings.write_string(sb, ": ");
    }
    strings.write_string(sb, " switch ");
    if r.tag != nil {
        fmt.println("aaa\n", r.tag.derived);
        switch s in &r.tag.derived {
            case ast.Assign_Stmt: generate_assign_stmt(sb, &s, indent);
            case: fmt.println("generate_type_switch_stmt tag\n", s^);
        }
    }
    if r.expr != nil {
        switch s in &r.expr.derived {
            case: fmt.println("generate_type_switch_stmt expr\n", s^);
        }
    }
    strings.write_string(sb, " {\n    ");
    if r.body != nil {
        switch s in &r.body.derived {
            case ast.Block_Stmt: generate_block_stmt(sb, &s, indent + 1);
            case: fmt.println("generate_type_switch_stmt body\n", s^);
        }
    }
    strings.write_string(sb, "    }\n");
}

generate_switch_stmt :: proc(sb: ^strings.Builder, r: ^ast.Switch_Stmt, indent: int) {
    if r.partial {
        strings.write_string(sb, "#partial ");
    }
    if r.label != nil {
        switch s in &r.label.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_switch_stmt label\n", s^);
        }
        strings.write_string(sb, ": ");
    }
    strings.write_string(sb, " switch ");
    if r.init != nil {
        switch s in &r.init.derived {
            case ast.Value_Decl: generate_value_decl(sb, &s, indent);
            case: fmt.println("generate_switch_stmt init\n", s^);
        }
        strings.write_string(sb, " ");
    }
    if r.cond != nil {
        switch s in &r.cond.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_switch_stmt cond\n", s^);
        }
    }
    strings.write_string(sb, " {\n    ");
    if r.body != nil {
        switch s in &r.body.derived {
            case ast.Block_Stmt: generate_block_stmt(sb, &s, indent + 1);
            case: fmt.println("generate_switch_stmt body\n", s^);
        }
    }
    strings.write_string(sb, "    }\n");
}

generate_range_stmt :: proc(sb: ^strings.Builder, r: ^ast.Range_Stmt, indent: int) {
    if r.label != nil {
        switch s in &r.label.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_range_stmt label\n", s^);
        }
        strings.write_string(sb, ": ");
    }
    strings.write_string(sb, "for ");
    if r.val0 != nil {
        switch s in &r.val0.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_range_stmt val0\n", s^);
        }
    }
    if r.val1 != nil {
        strings.write_string(sb, ", ");
        switch s in &r.val1.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_range_stmt val1\n", s^);
        }
    }
    strings.write_string(sb, " in ");
    if r.expr != nil {
        switch s in &r.expr.derived {
            case ast.Binary_Expr: generate_binary_expr(sb, &s, indent);
            case ast.Ident:       generate_ident(sb, &s, indent, false);
            case ast.Paren_Expr:  generate_paren_expr(sb, &s, indent);
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case: fmt.println("generate_range_stmt expr\n", s^);
        }
    }
    if r.body != nil {
        switch s in &r.body.derived {
            case ast.Block_Stmt: {
                if s.uses_do {
                    strings.write_string(sb, " do ");
                    generate_block_stmt(sb, &s, indent);
                } else {
                    strings.write_string(sb, " {\n    ");
                    generate_block_stmt(sb, &s, indent);
                    strings.write_string(sb, "    }");
                }
            }
            case: fmt.println("generate_range_stmt body\n", s^);
        }
    }
}

generate_for_stmt :: proc(sb: ^strings.Builder, r: ^ast.For_Stmt, indent: int) {
    if r.label != nil {
        switch s in &r.label.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_range_stmt label\n", s^);
        }
        strings.write_string(sb, ": ");
    }
    strings.write_string(sb, "for ");
    if r.init != nil {
        switch s in &r.init.derived {
            case ast.Value_Decl: {
                generate_value_decl(sb, &s, indent);
                strings.write_string(sb, " ");
            }
            case: fmt.println("generate_for_stmt init\n", s^);
        }
    }
    if r.cond != nil {
        switch s in &r.cond.derived {
            case ast.Binary_Expr: {
                generate_binary_expr(sb, &s, indent);
                strings.write_string(sb, "; ");
            }
            case: fmt.println("generate_for_stmt cond\n", s^);
        }
    }
    if r.post != nil {
        switch s in &r.post.derived {
            case ast.Assign_Stmt: {
                generate_assign_stmt(sb, &s, indent);
            }
            case: fmt.println("generate_for_stmt post\n", s^);
        }
    }
    if r.body != nil {
        switch s in &r.body.derived {
            case ast.Block_Stmt: {
                if s.uses_do {
                    strings.write_string(sb, " do ");
                    generate_block_stmt(sb, &s, indent);
                } else {
                    strings.write_string(sb, " {\n    ");
                    generate_block_stmt(sb, &s, indent);
                    strings.write_string(sb, "    }");
                }
            }
            case: fmt.println("generate_for_stmt body\n", s^);
        }
    }
}

generate_if_stmt :: proc(sb: ^strings.Builder, r: ^ast.If_Stmt, indent: int) {
    if r.label != nil {
        switch s in &r.label.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_range_stmt label\n", s^);
        }
        strings.write_string(sb, ": ");
    }
    strings.write_string(sb, "if ");
    if r.init != nil {
        switch s in &r.init.derived {
            case ast.Value_Decl: generate_value_decl(sb, &s, indent);
            case: fmt.println("generate_if_stmt init\n", s^);
        }
    }
    switch s in &r.cond.derived {
        case ast.Ident:       generate_ident(sb, &s, indent, false);
        case ast.Binary_Expr: generate_binary_expr(sb, &s, indent);
        case ast.Unary_Expr:  generate_unary_expr(sb, &s, indent);
        case ast.Call_Expr:   generate_call_expr(sb, &s, indent);
        case: fmt.println("generate_if_stmt cond\n", s^);
    }
    switch s in &r.body.derived {
        case ast.Block_Stmt: {
            if s.uses_do {
                strings.write_string(sb, " do ");
                generate_block_stmt(sb, &s, indent);
            } else {
                strings.write_string(sb, " {\n    ");
                generate_block_stmt(sb, &s, indent);
                strings.write_string(sb, "    }");
            }
        }
        case: fmt.println("generate_if_stmt body\n", s^);
    }
    if r.else_stmt != nil {
        strings.write_string(sb, "    else ");
        switch s in &r.else_stmt.derived {
            case ast.If_Stmt: {
                generate_if_stmt(sb, &s, indent);
            } 
            case ast.Block_Stmt: {
                if s.uses_do {
                    strings.write_string(sb, " do ");
                    generate_block_stmt(sb, &s, indent);
                } else {
                    strings.write_string(sb, " {\n    ");
                    generate_block_stmt(sb, &s, indent);
                    strings.write_string(sb, "    }");
                }
            } 
            case: fmt.println("generate_if_stmt else\n", s^);
        }
    }
}

generate_when_stmt :: proc(sb: ^strings.Builder, r: ^ast.When_Stmt, indent: int) {
    strings.write_string(sb, "when ");
    switch s in &r.cond.derived {
        case ast.Ident:       generate_ident(sb, &s, indent, false);
        case ast.Binary_Expr: generate_binary_expr(sb, &s, indent);
        case ast.Unary_Expr:  generate_unary_expr(sb, &s, indent);
        case: fmt.println("generate_when_stmt cond\n", s^);
    }
    switch s in &r.body.derived {
        case ast.Block_Stmt: {
            if s.uses_do {
                strings.write_string(sb, " do ");
                generate_block_stmt(sb, &s, indent);
            } else {
                strings.write_string(sb, " {\n    ");
                generate_block_stmt(sb, &s, indent);
                strings.write_string(sb, "    }");
            }
        }
        case: fmt.println("generate_when_stmt body\n", s^);
    }
    if r.else_stmt != nil {
        strings.write_string(sb, " else ");
        switch s in &r.else_stmt.derived {
            case ast.When_Stmt:    generate_when_stmt(sb, &s, indent);
            case ast.Block_Stmt: {
                if s.uses_do {
                    strings.write_string(sb, " do ");
                    generate_block_stmt(sb, &s, indent);
                } else {
                    strings.write_string(sb, " {\n    ");
                    generate_block_stmt(sb, &s, indent);
                    strings.write_string(sb, "    }");
                }
            }
            case: fmt.println("generate_when_stmt else\n", s^);
        }
    }
}

generate_return_stmt :: proc(sb: ^strings.Builder, r: ^ast.Return_Stmt, indent: int) {
    strings.write_string(sb, "return");
    results_length := len(r.results);
    if results_length > 0 do strings.write_string(sb, " ");
    for v, i in r.results {
        switch s in &v.derived {
            case ast.Slice_Expr:  generate_slice_expr(sb, &s, indent);
            case ast.Call_Expr:   generate_call_expr(sb, &s, indent);
            case ast.Unary_Expr:  generate_unary_expr(sb, &s, indent);
            case ast.Basic_Lit:   generate_basic_lit(sb, &s, indent);
            case ast.Expr_Stmt:   generate_expr_stmt(sb, &s, indent);
            case ast.Ident:       generate_ident(sb, &s, indent, false);
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case ast.Binary_Expr: generate_binary_expr(sb, &s, indent);
            case ast.Type_Cast:   generate_type_cast(sb, &s, indent);
            case ast.Deref_Expr:  generate_deref_expr(sb, &s, indent);
            case ast.Comp_Lit:    generate_comp_lit(sb, &s, indent);
            case ast.Index_Expr:  generate_index_expr(sb, &s, indent);
            case ast.Implicit_Selector_Expr: generate_implicit_selector_expr(sb, &s, indent);
            case: fmt.println("generate_return_stmt results\n", s^);
        }
        if results_length > 1 && i < results_length - 1 do strings.write_string(sb, ", ");
    }
    strings.write_string(sb, ";");
}

generate_expr_stmt :: proc(sb: ^strings.Builder, e: ^ast.Expr_Stmt, indent: int) {
    switch s in &e.expr.derived {
        case ast.Call_Expr: generate_call_expr(sb, &s, indent);
        case: fmt.println("generate_expr_stmt\n", s^);
    }
    strings.write_string(sb, ";");
}

generate_assign_stmt :: proc(sb: ^strings.Builder, a: ^ast.Assign_Stmt, indent: int) {
    lhs_length := len(a.lhs);
    for v, i in a.lhs {
        switch s in &v.derived {
            case ast.Index_Expr: generate_index_expr(sb, &s, indent);
            case ast.Selector_Expr: {
                generate_selector_expr(sb, &s, indent + 1);
                if lhs_length > 1 && i < lhs_length - 1 do strings.write_string(sb, ", ");  
            }
            case ast.Ident: {
                generate_ident(sb, &s, indent, false);
                if lhs_length > 1 && i < lhs_length - 1 do strings.write_string(sb, ", ");       
            }
            case ast.Deref_Expr: generate_deref_expr(sb, &s, indent);
            case: fmt.println("generate_assign_stmt lhs\n", s^);
        }
    }
    strings.write_string(sb, " ");
    strings.write_string(sb, a.op.text);
    strings.write_string(sb, " ");
    rhs_length := len(a.rhs);
    for v, i in a.rhs {
        switch s in &v.derived {
            case ast.Basic_Lit:  generate_basic_lit(sb, &s, indent);
            case ast.Ident:  generate_ident(sb, &s, indent, false);
            case ast.Comp_Lit:   generate_comp_lit(sb, &s, indent);
            case ast.Call_Expr: generate_call_expr(sb, &s, indent);
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case ast.Binary_Expr:   generate_binary_expr(sb, &s, indent);
            case ast.Unary_Expr:    generate_unary_expr(sb, &s, indent);
            case ast.Index_Expr:    generate_index_expr(sb, &s, indent);
            case ast.Slice_Expr:    generate_slice_expr(sb, &s, indent);
            case ast.Implicit_Selector_Expr: generate_implicit_selector_expr(sb, &s, indent);
            case: fmt.println("generate_assign_stmt rhs\n", s^);
        }
        if rhs_length > 1 && i < rhs_length - 1 do strings.write_string(sb, ", ");
    }
}

///////////////////////////////////////////////
// Expressions
///////////////////////////////////////////////

generate_slice_expr :: proc(sb: ^strings.Builder, a: ^ast.Slice_Expr, indent: int) {
    switch s in &a.expr.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case ast.Slice_Expr: generate_slice_expr(sb, &s, indent);
        case: fmt.println("generate_slice_expr expr\n", s^);
    }
    strings.write_string(sb, "[");
    if a.low != nil {
        switch s in &a.low.derived {
            case ast.Basic_Lit: generate_basic_lit(sb, &s, indent);
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case ast.Binary_Expr:   generate_binary_expr(sb, &s, indent);
            case ast.Ident:         generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_slice_expr low\n", s^);
        }
    }
    strings.write_string(sb, a.interval.text);
    if a.high != nil {
        switch s in &a.high.derived {
            case ast.Basic_Lit: generate_basic_lit(sb, &s, indent);
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case ast.Ident:     generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_slice_expr high\n", s^);
        }
    }
    strings.write_string(sb, "]");
}

generate_selector_expr :: proc(sb: ^strings.Builder, s: ^ast.Selector_Expr, indent: int) {
    switch s in &s.expr.derived {
        case ast.Ident:    generate_ident(sb, &s, indent, false);
        case ast.Implicit: generate_implicit(sb, &s, indent);
        case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
        case ast.Call_Expr:     generate_call_expr(sb, &s, indent);
        case ast.Unary_Expr:    generate_unary_expr(sb, &s, indent);
        case: fmt.println("generate_selector_expr expr\n", s^);
    }
    strings.write_string(sb, ".");
    switch s in &s.field.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case: fmt.println("generate_selector_expr field\n", s^);
    }
}

generate_implicit_selector_expr :: proc(sb: ^strings.Builder, t: ^ast.Implicit_Selector_Expr, indent: int) {
    strings.write_string(sb, ".");
    switch s in &t.field.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case: fmt.println("generate_implicit_selector_expr elem\n", s^);
    }
}

generate_index_expr :: proc(sb: ^strings.Builder, c: ^ast.Index_Expr, indent: int) {
    switch s in &c.expr.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case: fmt.println("generate_index_expr expr\n", s^);
    }
    strings.write_string(sb, "[");
    switch s in &c.index.derived {
        case ast.Basic_Lit: generate_basic_lit(sb, &s, indent);
        case ast.Index_Expr: generate_index_expr(sb, &s, indent);
        case ast.Ident:     generate_ident(sb, &s, indent, false);
        case ast.Binary_Expr: generate_binary_expr(sb, &s, indent);
        case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
        case ast.Implicit_Selector_Expr: generate_implicit_selector_expr(sb, &s, indent);
        case: fmt.println("generate_index_expr index\n", s^);
    }
    strings.write_string(sb, "]");
}

generate_deref_expr :: proc(sb: ^strings.Builder, e: ^ast.Deref_Expr, indent: int) {
    switch s in &e.expr.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case ast.Call_Expr: generate_call_expr(sb, &s, indent);
        case: fmt.println("generate_deref_expr expr\n", s^);
    }
    strings.write_string(sb, e.op.text);
}

generate_call_expr :: proc(sb: ^strings.Builder, c: ^ast.Call_Expr, indent: int) {
    switch s in &c.expr.derived {
        case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
        case ast.Ident:         generate_ident(sb, &s, indent, false);
        case ast.Paren_Expr:    generate_paren_expr(sb, &s, indent);
        case ast.Implicit:      generate_implicit(sb, &s, indent);
        case ast.Basic_Directive: generate_basic_directive(sb, &s, indent);
        case: fmt.println("generate_call_expr expr\n", s^);
    }
    strings.write_string(sb, "(");
    for v, i in c.args {
        if c.ellipsis.kind == .Ellipsis && i == len(c.args) - 1 do strings.write_string(sb, "..");
        switch s in &v.derived {
            case ast.Basic_Lit:     generate_basic_lit(sb, &s, indent);
            case ast.Call_Expr:     generate_call_expr(sb, &s, indent);
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case ast.Binary_Expr:   generate_binary_expr(sb, &s, indent);
            case ast.Unary_Expr:    generate_unary_expr(sb, &s, indent);
            case ast.Ident:         generate_ident(sb, &s, indent, false);
            case ast.Poly_Type:     generate_poly_type(sb, &s, indent);
            case ast.Slice_Expr:    generate_slice_expr(sb, &s, indent);
            case ast.Deref_Expr:    generate_deref_expr(sb, &s, indent);
            case ast.Field_Value:   generate_field_value(sb, &s, indent);
            case ast.Array_Type:    generate_array_type(sb, &s, indent);
            case ast.Index_Expr:    generate_index_expr(sb, &s, indent);
            case ast.Dynamic_Array_Type: generate_dynamic_array_type(sb, &s, indent);
            case ast.Map_Type:      generate_map_type(sb, &s, indent);
            case ast.Pointer_Type:  generate_pointer_type(sb, &s, indent);
            case: fmt.println("generate_call_expr args\n", s^);
        }
        if i < len(c.args) - 1 do strings.write_string(sb, ", ");
    }
    strings.write_string(sb, ")");
}

generate_binary_expr :: proc(sb: ^strings.Builder, b: ^ast.Binary_Expr, indent: int) {
    switch s in &b.left.derived {
        case ast.Call_Expr:     generate_call_expr(sb, &s, indent);
        case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
        case ast.Basic_Lit:     generate_basic_lit(sb, &s, indent);
        case ast.Ident:         generate_ident(sb, &s, indent, false);
        case ast.Binary_Expr:   generate_binary_expr(sb, &s, indent);
        case ast.Paren_Expr:    generate_paren_expr(sb, &s, indent);
        case ast.Index_Expr:    generate_index_expr(sb, &s, indent);
        case: fmt.println("generate_binary_expr left\n", s^);
    }
    strings.write_string(sb, " ");
    strings.write_string(sb, b.op.text);
    strings.write_string(sb, " ");
    switch s in &b.right.derived {
        case ast.Call_Expr:     generate_call_expr(sb, &s, indent);
        case ast.Basic_Lit:     generate_basic_lit(sb, &s, indent);
        case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
        case ast.Ident:         generate_ident(sb, &s, indent, false);
        case ast.Binary_Expr:   generate_binary_expr(sb, &s, indent);
        case ast.Paren_Expr:    generate_paren_expr(sb, &s, indent);
        case ast.Unary_Expr:    generate_unary_expr(sb, &s, indent);
        case ast.Index_Expr:    generate_index_expr(sb, &s, indent);
        case ast.Array_Type:    generate_array_type(sb, &s, indent);
        case: fmt.println("generate_binary_expr right\n", s^);
    }
}

generate_unary_expr :: proc(sb: ^strings.Builder, u: ^ast.Unary_Expr, indent: int) {
    strings.write_string(sb, u.op.text);
    if u.expr != nil {
        switch s in &u.expr.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case ast.Basic_Lit:    generate_basic_lit(sb, &s, indent);
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case ast.Paren_Expr:   generate_paren_expr(sb, &s, indent);
            case: fmt.println("generate_unary_expr\n", s^);
        }
    }
}

generate_paren_expr :: proc(sb: ^strings.Builder, p: ^ast.Paren_Expr, indent: int) {
    strings.write_string(sb, "(");
    switch s in &p.expr.derived {
        case ast.Binary_Expr:  generate_binary_expr(sb, &s, indent);
        case ast.Pointer_Type: generate_pointer_type(sb, &s, indent);
        case ast.Comp_Lit:     generate_comp_lit(sb, &s, indent);
        case: fmt.println("generate_paren_expr\n", s^);
    }
    strings.write_string(sb, ")");
}

///////////////////////////////////////////////
// Misc
///////////////////////////////////////////////

generate_proc_group :: proc(sb: ^strings.Builder, a: ^ast.Proc_Group, indent: int) {
    strings.write_string(sb, a.tok.text);
    if a.args != nil {
        strings.write_string(sb, "{");
        args_length := len(a.args);
        for v, i in a.args {
            switch s in &v.derived {
                case ast.Ident: generate_ident(sb, &s, indent, false);
                case: fmt.println("generate_proc_group args\n", s^);
            }
            if args_length > 1 && i < args_length - 1 do strings.write_string(sb, ", ");
        }
        strings.write_string(sb, "}");
    }
}

generate_proc_lit :: proc(sb: ^strings.Builder, p: ^ast.Proc_Lit, indent: int) {
    switch s in &p.type.derived {
        case ast.Proc_Type: {
            strings.write_string(sb, " :: ");
            switch p.inlining {
                case .None: 
                case .Inline:    strings.write_string(sb, "inline ");
                case .No_Inline: strings.write_string(sb, "no_inline ");
            }
            generate_proc_type(sb, &s, indent);
        }
        case: fmt.println("generate_proc_lit type\n", s^);
    }
    if p.where_token.kind == tokenizer.Token_Kind.Where {
        strings.write_string(sb, " ");
        strings.write_string(sb, p.where_token.text);
        strings.write_string(sb, " ");
        
        where_clauses_length := len(p.where_clauses);
        for v, i in p.where_clauses {
            switch s in &v.derived {
                case ast.Binary_Expr: generate_binary_expr(sb, &s, indent);
                case: fmt.println("generate_proc_lit where_clauses\n", s^);
            }
            if where_clauses_length > 1 && i < where_clauses_length - 1 do strings.write_string(sb, ", ");
        }
    }
    strings.write_string(sb, " {\n");
    if p.body != nil {
        switch s in &p.body.derived {
            case ast.Block_Stmt: generate_block_stmt(sb, &s, indent + 1);
            case: fmt.println("generate_proc_lit body\n", s^);
        }
    }
    strings.write_string(sb, "}\n");
}

generate_attribute :: proc(sb: ^strings.Builder, a: ^ast.Attribute, indent: int) {
    for v, _ in a.elems {
        switch s in &v.derived {
            case ast.Ident: {
                strings.write_string(sb, "@");
                generate_ident(sb, &s, indent, true);
                strings.write_string(sb, "\n");
            }
            case ast.Field_Value: {
                strings.write_string(sb, "@(");
                generate_field_value(sb, &s, indent);
                strings.write_string(sb, ")\n");
            }
            case: fmt.println("generate_attribute\n", s^);
        }
    }
}

generate_ident :: proc(sb: ^strings.Builder, i: ^ast.Ident, indent: int, check_attr: bool) {
    populate_meta_info(i, check_attr);
    strings.write_string(sb, i.name);
}

generate_undef :: proc(sb: ^strings.Builder, a: ^ast.Undef, indent: int) {
    strings.write_string(sb, " ---");
}

generate_value :: proc(sb: ^strings.Builder, t: ^tokenizer.Token, indent: int) {
    strings.write_string(sb, t.text);
}

// @todo(zh): Figure out a better to do this, since bit fields use `:` and not `=`
generate_field_value :: proc(sb: ^strings.Builder, f: ^ast.Field_Value, indent: int, assign := "=") {
    switch s in &f.field.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case ast.Basic_Lit: generate_basic_lit(sb, &s, indent);
        case ast.Binary_Expr: generate_binary_expr(sb, &s, indent);
        case: fmt.println("generate_field_value field\n", s^);
    }
    switch s in &f.value.derived {
        case ast.Basic_Lit: {
            strings.write_string(sb, assign);
            generate_basic_lit(sb, &s, indent);
        }
        case ast.Binary_Expr: {
            strings.write_string(sb, assign);
            generate_binary_expr(sb, &s, indent);
        }
        case ast.Ident: {
            strings.write_string(sb, assign);
            generate_ident(sb, &s, indent, false);
        }
        case: fmt.println("generate_field_value value\n", s^);
    }
}

generate_field_list :: proc(sb: ^strings.Builder, p: ^ast.Field_List, indent: int) {
    length := len(p.list);
    for v, _ in p.list {
        for in 0..<indent do strings.write_string(sb, "    ");
        switch s in &v.derived {
            case ast.Field: {
                generate_field(sb, &s, indent);
                if length > 1 do strings.write_string(sb, ",\n");
            }  
            case: fmt.println("generate_field_list\n", s^);
        }
    }
}

generate_field :: proc(sb: ^strings.Builder, f: ^ast.Field, indent: int) {
    names_length := len(f.names);
    for v, i in f.names {
        switch s in &v.derived {
            case ast.Ident: {
                generate_ident(sb, &s, indent, false);
                if names_length > 1 && i < names_length - 1 do strings.write_string(sb, ", ");
            }
            case: fmt.println("generate_field names\n", s^);
        }
    }
    if f.type != nil {
        strings.write_string(sb, ": ");
        switch s in &f.type.derived {
            case ast.Ident:         generate_ident(sb, &s, indent, false);
            case ast.Poly_Type:     generate_poly_type(sb, &s, indent);
            case ast.Pointer_Type:  generate_pointer_type(sb, &s, indent);
            case ast.Typeid_Type:   generate_typeid_type(sb, &s, indent);
            case ast.Array_Type:    generate_array_type(sb, &s, indent);
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case ast.Ellipsis:      generate_ellipsis(sb, &s, indent);
            case ast.Call_Expr:     generate_call_expr(sb, &s, indent);
            case: fmt.println("generate_field type\n", s^);
        } 
    }
    if f.tag.text != "" {
        strings.write_string(sb, " ");
        strings.write_string(sb, f.tag.text);
    }
    if f.default_value != nil {
        if f.type == nil do strings.write_string(sb, " := ");
        else do strings.write_string(sb, " = ");
        switch s in &f.default_value.derived {
            case ast.Basic_Directive: generate_basic_directive(sb, &s, indent);
            case ast.Selector_Expr:   generate_selector_expr(sb, &s, indent);
            case ast.Basic_Lit:       generate_basic_lit(sb, &s, indent);
            case ast.Ident:           generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_field default_value\n", s^);
        } 
    }
}

generate_ellipsis :: proc(sb: ^strings.Builder, e: ^ast.Ellipsis, indent: int) {
    strings.write_string(sb, "..");
    switch s in &e.expr.derived {
        case ast.Ident: generate_ident(sb, &s, indent, false);
        case: fmt.println("generate_ellipsis expr\n", s^);
    }
}

generate_basic_directive :: proc(sb: ^strings.Builder, t: ^ast.Basic_Directive, indent: int) {
    strings.write_string(sb, t.tok.text);
    strings.write_string(sb, t.name);
}

generate_case_clause :: proc(sb: ^strings.Builder, r: ^ast.Case_Clause, indent: int) {
    strings.write_string(sb, "case ");
    if r.list != nil {
        for v, i in r.list {
            switch s in &v.derived {
                case ast.Implicit_Selector_Expr: generate_implicit_selector_expr(sb, &s, indent);
                case ast.Selector_Expr:          generate_selector_expr(sb, &s, indent);
                case ast.Basic_Lit:              generate_basic_lit(sb, &s, indent);
                case ast.Binary_Expr:            generate_binary_expr(sb, &s, indent);
                case ast.Ident:                  generate_ident(sb, &s, indent, false);
                case: fmt.println("generate_case_clause list\n", s^);
            }
        }
    }
    strings.write_string(sb, r.terminator.text);
    if r.body != nil {
        for v, i in r.body {
            switch s in &v.derived {
                case ast.Expr_Stmt: generate_expr_stmt(sb, &s, indent);
                case ast.Branch_Stmt: generate_branch_stmt(sb, &s, indent);
                case ast.Return_Stmt: generate_return_stmt(sb, &s, indent);
                case ast.Block_Stmt: generate_block_stmt(sb, &s, indent);
                case: fmt.println("generate_case_clause body\n", s^);
            }
            strings.write_string(sb, " ");
        }
    }
    strings.write_string(sb, "    \n");
}

generate_type_cast :: proc(sb: ^strings.Builder, t: ^ast.Type_Cast, indent: int) {
    strings.write_string(sb, t.tok.text);
    strings.write_string(sb, "(");
    if t.type != nil {
        switch s in &t.type.derived {
            case ast.Array_Type: generate_array_type(sb, &s, indent);
            case: fmt.println("generate_type_cast type\n", s^);
        }
    }
    strings.write_string(sb, ")");
    if t.expr != nil {
        switch s in &t.expr.derived {
            case ast.Ident: generate_ident(sb, &s, indent, false);
            case: fmt.println("generate_type_cast expr\n", s^);
        }
    }
}

generate_comp_lit :: proc(sb: ^strings.Builder, a: ^ast.Comp_Lit, indent: int) {
    if a.type != nil {
        switch s in &a.type.derived {
            case ast.Array_Type: {
                generate_array_type(sb, &s, indent);
                strings.write_string(sb, " ");
            }
            case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
            case ast.Map_Type:      generate_map_type(sb, &s, indent);
            case ast.Dynamic_Array_Type: generate_dynamic_array_type(sb, &s, indent);
            case ast.Ident:         generate_ident(sb, &s, indent, false);
            case ast.Bit_Set_Type:   generate_bit_set_type(sb, &s, indent);
            case: fmt.println("generate_comp_lit type\n", s^);
        }
    }
    if a.elems != nil {
        for v, i in a.elems {
            if i == 0 do strings.write_string(sb, "{");
            switch s in &v.derived {
                case ast.Basic_Lit:     generate_basic_lit(sb, &s, indent);
                case ast.Binary_Expr:   generate_binary_expr(sb, &s, indent);
                case ast.Selector_Expr: generate_selector_expr(sb, &s, indent);
                case ast.Unary_Expr:    generate_unary_expr(sb, &s, indent);
                case ast.Comp_Lit:      generate_comp_lit(sb, &s, indent);
                case ast.Ident:         generate_ident(sb, &s, indent, false);
                case ast.Call_Expr:     generate_call_expr(sb, &s, indent);
                case ast.Slice_Expr:    generate_slice_expr(sb, &s, indent);
                case ast.Field_Value:   generate_field_value(sb, &s, indent);
                case ast.Implicit_Selector_Expr: generate_implicit_selector_expr(sb, &s, indent);
                case: fmt.println("generate_comp_lit elems\n", s^);
            }
            if i == len(a.elems) - 1 do strings.write_string(sb, "}");
            else do strings.write_string(sb, ", ");
        }
    } else {
        strings.write_string(sb, "{}");
    }
}


generate_implicit :: proc(sb: ^strings.Builder, b: ^ast.Implicit, indent: int) {
    strings.write_string(sb, b.tok.text);
}

generate_basic_lit :: proc(sb: ^strings.Builder, b: ^ast.Basic_Lit, indent: int) {
    #partial switch b.tok.kind {
        case: generate_value(sb, &b.tok, indent);
    }
}