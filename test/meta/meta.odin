package meta

import "core:odin/ast"
import "core:odin/parser"
import "core:odin/tokenizer"
import "core:os"
import "core:fmt"
import "core:strings"

tk :: tokenizer.Token_Kind;

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

write_file_raw :: proc(path: string, data: []byte) -> bool {
    file, err := os.open(path, os.O_RDWR | os.O_CREATE | os.O_TRUNC);
    if err != os.ERROR_NONE do return false;
    defer os.close(file);

    if _, err := os.write(file, data); err != os.ERROR_NONE do return false;
    return true;
}
meta: [dynamic]Meta;
curr_index: int = -1;
found_attr: bool = false;

main :: proc() {
    path := "C:/Dev/odin/odin-test/example/ast_printer_test.odin";
    data, err := os.read_entire_file(path);
    sb := strings.make_builder();

    p := parser.Parser{};
    f := ast.File{
            src = data, 
            fullpath = path,
    };

    if res := parser.parse_file(&p, &f); res {
        root := p.file;
        indent := 0;

        strings.write_string(&sb, "package ");
        strings.write_string(&sb, root.pkg_name);
        strings.write_string(&sb, "\n\n");

        for v, _ in root.decls {
            switch s in &v.derived {
                case ast.Import_Decl:   generate_import_decl(&sb, s, indent);
                case ast.Value_Decl:    generate_value_decl(&sb, s, indent);
                case: fmt.println("main\n", s^);
            }
        }
    }
    //generate_main(&sb);
    fmt.println(strings.to_string(sb));
}

generate_main :: proc(sb: ^strings.Builder) {
    strings.write_string(sb, "\nmain :: proc() {\n");
    bf_each: Meta;
    for v in meta do if v.kind == MetaKind.BeforeEach do bf_each = v;
    for v in meta {
        if bf_each.kind != nil && v.kind != MetaKind.BeforeEach {
            strings.write_string(sb, "   ");
            strings.write_string(sb, bf_each.text);
            strings.write_string(sb, "();\n");
        } 
        if v.kind == MetaKind.Test {
            strings.write_string(sb, "   ");
            strings.write_string(sb, v.text);
            strings.write_string(sb, "();\n");
        }
    }
    strings.write_string(sb, "\n}");
}

populate_meta_info :: proc(sb: ^strings.Builder, i: ^ast.Ident, indent: int, check_attr: bool) {
    if check_attr {
        switch i.name {
            case meta_kinds[MetaKind.BeforeEach]: {
                append(&meta, Meta{kind = MetaKind.BeforeEach});
                found_attr, curr_index = true, curr_index + 1;
            }
            case meta_kinds[MetaKind.Test]: {
                append(&meta, Meta{kind = MetaKind.Test});
                found_attr, curr_index = true, curr_index + 1;
            }
        }
    } else do if found_attr do meta[curr_index].text, found_attr = i.name, false;
}

generate_import_decl :: proc(sb: ^strings.Builder, decl: ^ast.Import_Decl, indent: int) {
    if decl.is_using do strings.write_string(sb, "using ");
    strings.write_string(sb, decl.import_tok.text);
    if decl.name.text != "" {
        strings.write_string(sb, " ");
        strings.write_string(sb, decl.name.text);
    }
    strings.write_string(sb, " ");   
    strings.write_string(sb, decl.relpath.text);
    strings.write_string(sb, "\n");
}

generate_value_decl :: proc(sb: ^strings.Builder, decl: ^ast.Value_Decl, indent: int) {
    if decl.is_using do strings.write_string(sb, "using ");
    if decl.type == nil do strings.write_string(sb, "\n");
    for v, _ in decl.attributes {
        switch s in &v.derived {
            case ast.Attribute: generate_attribute(sb, s, indent);
            case: fmt.println("generate_value_decl attributes\n", s^);
        }
    }    
    names_length := len(decl.names);
    for v, i in decl.names {
        switch s in &v.derived {
            case ast.Ident: {
                generate_ident(sb, s, indent, false);
                if names_length > 1 && i < names_length - 1 do strings.write_string(sb, ", ");
            }
            case: fmt.println("generate_value_decl names\n", s^);
        }
    }
    if decl.type != nil {
        switch s in &decl.type.derived {
            case ast.Selector_Expr: {
                strings.write_string(sb, ": ");
                generate_selector_expr(sb, s, indent);
                strings.write_string(sb, ";\n");
            }
            case ast.Ident: {
                strings.write_string(sb, ": ");
                generate_ident(sb, s, indent, false);
                strings.write_string(sb, ";\n");
            }
            case: fmt.println("generate_value_decl type\n", s^);
        }
    }
    values_length := len(decl.values);
    for v, i in decl.values {
        switch s in &v.derived {
            case ast.Proc_Lit: {
                generate_proc_lit(sb, s, indent);
            }
            case ast.Basic_Lit: {
                if i == 0 {
                    if decl.is_mutable do strings.write_string(sb, " := ");
                    else if !decl.is_mutable do strings.write_string(sb, " :: ");
                }
                generate_basic_lit(sb, s, indent);
                if values_length > 1 && i < values_length - 1 do strings.write_string(sb, ", ");
                if i == values_length - 1 do strings.write_string(sb, ";\n");
            }
            case ast.Ident: {
                if i == 0 {
                    if decl.is_mutable do strings.write_string(sb, " := ");
                    else if !decl.is_mutable do strings.write_string(sb, " :: ");
                }
                generate_ident(sb, s, indent, false);
                if i == values_length - 1 do strings.write_string(sb, ";\n");
            }
            case ast.Struct_Type: {
                generate_struct_type(sb, s, indent);
            }
            case ast.Union_Type: generate_union_type(sb, s, indent);
            case ast.Call_Expr: {
                strings.write_string(sb, " := ");
                generate_call_expr(sb, s, indent);
            }
            case: fmt.println("generate_value_decl values\n", s^);
        }
    }   
}

generate_struct_type :: proc(sb: ^strings.Builder, st: ^ast.Struct_Type, indent: int) {
    switch s in &st.fields.derived {
        case ast.Field_List: {
            strings.write_string(sb, " :: struct");
            if st.is_packed     do strings.write_string(sb, " #packed");
            if st.is_raw_union  do strings.write_string(sb, " #raw_union");
            strings.write_string(sb, " {\n");
            generate_field_list(sb, s, indent);
        }
        case: fmt.println("generate_struct_type\n", s^);
    }
    strings.write_string(sb, "\n};\n");
}

generate_union_type :: proc(sb: ^strings.Builder, u: ^ast.Union_Type, indent: int) {
    strings.write_string(sb, " :: union");
    strings.write_string(sb, " {\n");
    ind := indent + 1;
    for v, _ in u.variants {
        for in 0..ind-1 do strings.write_string(sb, "    ");
        switch s in &v.derived {
            case ast.Ident: {
                generate_ident(sb, s, indent, false);
                strings.write_string(sb, ",\n");
            }
            case: fmt.println("generate_union_type\n", s^);
        }
    }
    strings.write_string(sb, "}\n");
}

generate_attribute :: proc(sb: ^strings.Builder, a: ^ast.Attribute, indent: int) {
    for v, _ in a.elems {
        switch s in &v.derived {
            case ast.Ident: {
                strings.write_string(sb, "@");
                generate_ident(sb, s, indent, true);
                strings.write_string(sb, "\n");
            }
            case ast.Field_Value: {
                strings.write_string(sb, "@(");
                generate_field_value(sb, s, indent);
                strings.write_string(sb, ")\n");
            }
            case: fmt.println("generate_attribute\n", s^);
        }
    }
}

generate_ident :: proc(sb: ^strings.Builder, i: ^ast.Ident, indent: int, check_attr: bool) {
    populate_meta_info(sb, i, indent, check_attr);
    strings.write_string(sb, i.name);
}

generate_field_value :: proc(sb: ^strings.Builder, f: ^ast.Field_Value, indent: int) {
    switch s in &f.field.derived {
        case ast.Ident: generate_ident(sb, s, indent, false);
        case: fmt.println("generate_field_value field\n", s^);
    }
    switch s in &f.value.derived {
        case ast.Basic_Lit: {
            strings.write_string(sb, "=");
            generate_basic_lit(sb, s, indent);
        }
        case: fmt.println("generate_field_value value\n", s^);
    }
}

generate_proc_lit :: proc(sb: ^strings.Builder, p: ^ast.Proc_Lit, indent: int) {
    switch s in &p.type.derived {
        case ast.Proc_Type: {
            strings.write_string(sb, " :: ");
            if p.inlining == ast.Proc_Inlining.Inline do strings.write_string(sb, "inline ");
            generate_proc_type(sb, s, indent);
        }
        case: fmt.println("generate_proc_lit type\n", s^);
    }
    strings.write_string(sb, " {\n");
    switch s in &p.body.derived {
        case ast.Block_Stmt: generate_block_stmt(sb, s, indent);
        case: fmt.println("generate_proc_lit body\n", s^);
    }
    strings.write_string(sb, "}\n");
}

generate_proc_type :: proc(sb: ^strings.Builder, p: ^ast.Proc_Type, indent: int) {
    switch p.tok.kind {
        case tokenizer.Token_Kind.Proc: {
            generate_value(sb, &p.tok, indent);
        }
        case: fmt.println("generate_proc_type tok\n", p.tok.kind);
    }
    switch p.calling_convention {
        case .Odin:
        case .Contextless: strings.write_string(sb, " \"contextless\" ");
        case .C_Decl: strings.write_string(sb, " \"c\" ");
        case .Std_Call: strings.write_string(sb, " \"std\" ");
        case .Fast_Call: strings.write_string(sb, " \"fast\" ");
    }
    strings.write_string(sb, "(");
    params_length := len(p.params.list);
    for v, i in p.params.list {
        switch s in &v.derived {
            case ast.Field_List: generate_field_list(sb, s, indent);
            case ast.Field: {
                generate_field(sb, s, indent);
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
                            if res_length == 1 do strings.write_string(sb, "(");
                            generate_ident(sb, b, indent, false);
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
                case ast.Ident: {
                    generate_ident(sb, s, indent, false);
                    if res_length > 1 && i < res_length - 1 do strings.write_string(sb, ", ");
                    if has_name && res_length == 1 do strings.write_string(sb, ")");
                }
                case: fmt.println("generate_proc_type results type\n", s^);
            }
        }
        if res_length > 1 do strings.write_string(sb, ") ");
    }
}

generate_field_list :: proc(sb: ^strings.Builder, p: ^ast.Field_List, indent: int) {
    ind := indent + 1;
    for v, _ in p.list {
        for in 0..ind-1 do strings.write_string(sb, "    ");
        switch s in &v.derived {
            case ast.Field:   generate_field(sb, s, indent);
            case: fmt.println("generate_field_list\n", s^);
        }
    }
}

generate_field :: proc(sb: ^strings.Builder, f: ^ast.Field, indent: int) {
    names_length := len(f.names);
    for v, i in f.names {
        switch s in &v.derived {
            case ast.Ident: {
                generate_ident(sb, s, indent, false);
                if names_length > 1 && i < names_length - 1 do strings.write_string(sb, ", ");
            }
            case: fmt.println("generate_field names\n", s^);
        }
    }
    strings.write_string(sb, ": ");
    switch s in &f.type.derived {
        case ast.Ident: generate_ident(sb, s, indent, false);
        case: fmt.println("generate_field type\n", s^);
    }
    if f.tag.text != "" {
        strings.write_string(sb, " ");
        strings.write_string(sb, f.tag.text);
    }
}

generate_block_stmt :: proc(sb: ^strings.Builder, b: ^ast.Block_Stmt, indent: int) {
    ind := indent + 1;
    for v, _ in b.stmts {
        for in 0..ind-1 do strings.write_string(sb, "    ");
        switch s in &v.derived {
            case ast.Assign_Stmt:   generate_assign_stmt(sb, s, indent);
            case ast.Expr_Stmt:     generate_expr_stmt(sb, s, indent);
            case ast.Return_Stmt:   generate_return_stmt(sb, s, indent);
            case ast.Value_Decl:   generate_value_decl(sb, s, indent);
            case: fmt.println("generate_block_stmt\n", s^);
        }
    }
}

generate_return_stmt :: proc(sb: ^strings.Builder, r: ^ast.Return_Stmt, indent: int) {
    strings.write_string(sb, "return");
    results_length := len(r.results);
    if results_length > 0 do strings.write_string(sb, " ");
    for v, i in r.results {
        switch s in &v.derived {
            case ast.Basic_Lit:   generate_basic_lit(sb, s, indent);
            case ast.Expr_Stmt:   generate_expr_stmt(sb, s, indent);
            case ast.Ident: {
                generate_ident(sb, s, indent, false);
                if results_length > 1 && i < results_length - 1 do strings.write_string(sb, ", ");
            }
            case: fmt.println("generate_return_stmt\n", s^);
        }
    }
    strings.write_string(sb, ";\n");
}

generate_assign_stmt :: proc(sb: ^strings.Builder, a: ^ast.Assign_Stmt, indent: int) {
    lhs_length := len(a.lhs);
    for v, i in a.lhs {
        switch s in &v.derived {
            case ast.Selector_Expr: {
                generate_selector_expr(sb, s, indent);
                if lhs_length > 1 && i < lhs_length - 1 do strings.write_string(sb, ", ");  
            }
            case ast.Ident: {
                generate_ident(sb, s, indent, false);
                if lhs_length > 1 && i < lhs_length - 1 do strings.write_string(sb, ", ");       
            }
            case: fmt.println("generate_assign_stmt lhs\n", s^);
        }
    }
    strings.write_string(sb, " = ");
    rhs_length := len(a.rhs);
    for v, i in a.rhs {
        switch s in &v.derived {
            case ast.Basic_Lit: {
                generate_basic_lit(sb, s, indent);
                if rhs_length > 1 && i < rhs_length - 1 do strings.write_string(sb, ", ");
            }
            case ast.Ident: {
                generate_ident(sb, s, indent, false);
                if rhs_length > 1 && i < rhs_length - 1 do strings.write_string(sb, ", ");
            }
            case ast.Comp_Lit: {
                generate_comp_lit(sb, s, indent);
            }
            case ast.Call_Expr: generate_call_expr(sb, s, indent);
            case: fmt.println("generate_assign_stmt rhs\n", s^);
        }
    }
    strings.write_string(sb, ";\n");
}

generate_comp_lit :: proc(sb: ^strings.Builder, c: ^ast.Comp_Lit, indent: int) {
    for v, i in c.elems {
        switch s in &v.derived {
            case ast.Binary_Expr:   {
                if i == 0 do strings.write_string(sb, "{");
                generate_binary_expr(sb, s, indent);
                if i == len(c.elems) - 1 do strings.write_string(sb, "}");
                else do strings.write_string(sb, ", ");
            }
            case: fmt.println("generate_comp_lit\n", s^);
        }
    }
}

generate_selector_expr :: proc(sb: ^strings.Builder, s: ^ast.Selector_Expr, indent: int) {
    switch s in &s.expr.derived {
        case ast.Ident: generate_ident(sb, s, indent, false);
        case: fmt.println("generate_selector_expr expr\n", s^);
    }
    strings.write_string(sb, ".");
    switch s in &s.field.derived {
        case ast.Ident: generate_ident(sb, s, indent, false);
        case: fmt.println("generate_selector_expr field\n", s^);
    }
}

generate_basic_lit :: proc(sb: ^strings.Builder, b: ^ast.Basic_Lit, indent: int) {
    switch b.tok.kind {
        case: generate_value(sb, &b.tok, indent);
    }
}

generate_value :: proc(sb: ^strings.Builder, t: ^tokenizer.Token, indent: int) {
    strings.write_string(sb, t.text);
}

generate_expr_stmt :: proc(sb: ^strings.Builder, e: ^ast.Expr_Stmt, indent: int) {
    switch s in &e.expr.derived {
        case ast.Call_Expr: generate_call_expr(sb, s, indent);
        case: fmt.println("generate_expr_stmt\n", s^);
    }
    strings.write_string(sb, ";\n");
}

generate_call_expr :: proc(sb: ^strings.Builder, c: ^ast.Call_Expr, indent: int) {
    switch s in &c.expr.derived {
        case ast.Selector_Expr: {
            generate_selector_expr(sb, s, indent);
        }
        case ast.Ident: {
            generate_ident(sb, s, indent, false);
        }
        case: fmt.println("generate_call_expr expr\n", s^);
    }
    strings.write_string(sb, "(");
    for v, i in c.args {
        switch s in &v.derived {
            case ast.Basic_Lit:     {
                generate_basic_lit(sb, s, indent);
            }
            case ast.Call_Expr:     {
                generate_call_expr(sb, s, indent);
            }
            case ast.Selector_Expr: {
                generate_selector_expr(sb, s, indent);
            }
            case ast.Binary_Expr:   {
                generate_binary_expr(sb, s, indent);
            }
            case ast.Unary_Expr:    {
                generate_unary_expr(sb, s, indent);
            }
            case: fmt.println("generate_call_expr args\n", s^);
        }
        if i < len(c.args) - 1 do strings.write_string(sb, ", ");
    }
    strings.write_string(sb, ")");
}

generate_binary_expr :: proc(sb: ^strings.Builder, b: ^ast.Binary_Expr, indent: int) {
    switch s in &b.left.derived {
        case ast.Call_Expr: {
            generate_call_expr(sb, s, indent);
        }
        case ast.Selector_Expr: {
                //strings.write_string(sb, ": ");
                generate_selector_expr(sb, s, indent);
                //strings.write_string(sb, ";\n");
        }
        case: fmt.println("generate_binary_expr left\n", s^);
    }
    strings.write_string(sb, " ");
    strings.write_string(sb, b.op.text);
    strings.write_string(sb, " ");
    switch s in &b.right.derived {
        case ast.Call_Expr: generate_call_expr(sb, s, indent);
        case ast.Basic_Lit: generate_basic_lit(sb, s, indent);
        case ast.Selector_Expr: {
                //strings.write_string(sb, ": ");
                generate_selector_expr(sb, s, indent);
                //strings.write_string(sb, ";\n");
        }
        case: fmt.println("generate_binary_expr right\n", s^);
    }
}

generate_unary_expr :: proc(sb: ^strings.Builder, u: ^ast.Unary_Expr, indent: int) {
    strings.write_string(sb, u.op.text);
    switch s in &u.expr.derived {
        case ast.Ident: {
            generate_ident(sb, s, indent, false);
        }
        case: fmt.println("generate_unary_expr\n", s^);
    }
}