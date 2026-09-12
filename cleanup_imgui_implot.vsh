#!/usr/bin/env -S v run

// V-native cleanup for bindings produced by `v translate` from cimgui/cimplot.
//
// Usage:
//   v run cleanup_imgui_implot.vsh input.v output.v imgui|implot

import os

struct Config {
	module_name string
	prefix      string
	lower       string
}

struct FnDecl {
	name   string
	params string
	ret    string
}

struct CleanupContext {
	kind         string
	cfg          Config
	header       string
	const_params map[string]bool
}

struct ExprParser {
	tokens []string
	known  map[string]i64
mut:
	pos int
}

fn usage() {
	eprintln('Usage: v run cleanup_imgui_implot.vsh input.v output.v imgui|implot')
	eprintln('       v run cleanup_imgui_implot.vsh --self-test')
}

fn config_for(kind string) !Config {
	return match kind {
		'imgui' { Config{'imgui', 'ImGui', 'im_gui_'} }
		'implot' { Config{'implot', 'ImPlot', 'im_plot_'} }
		else { error('unknown binding kind ${kind}') }
	}
}

fn is_ident_byte(c u8) bool {
	return c.is_alnum() || c == `_`
}

fn starts_upper(s string) bool {
	return s != '' && s[0] >= `A` && s[0] <= `Z`
}

fn is_lower_byte(c u8) bool {
	return c >= `a` && c <= `z`
}

fn is_digit_byte(c u8) bool {
	return c >= `0` && c <= `9`
}

fn without_prefix(value string, prefix string) string {
	return if value.starts_with(prefix) { value[prefix.len..] } else { value }
}

fn without_suffix(value string, suffix string) string {
	return if value.ends_with(suffix) { value[..value.len - suffix.len] } else { value }
}

fn before_or_self(value string, delimiter string) string {
	return if index := value.index(delimiter) { value[..index] } else { value }
}

fn strip_line_comment(line string) string {
	if index := line.index('//') {
		return line[..index]
	}
	return line
}

fn split_top_level_commas(s string) []string {
	mut parts := []string{}
	mut start := 0
	mut depth := 0
	for i, c in s {
		match c {
			`(`, `[` { depth++ }
			`)`, `]` {
				if depth > 0 { depth-- }
			}
			`,` {
				if depth == 0 {
					parts << s[start..i]
					start = i + 1
				}
			}
			else {}
		}
	}
	if start < s.len || s == '' {
		parts << s[start..]
	}
	return parts
}

fn parse_fn(line string) ?FnDecl {
	mut text := line.trim_space()
	if text.starts_with('pub ') {
		text = text[4..]
	}
	if !text.starts_with('fn ') {
		return none
	}
	open_index := text.index('(') or { return none }
	close_index := text.last_index(')') or { return none }
	if close_index < open_index {
		return none
	}
	name := text[3..open_index].trim_space()
	if name == '' || name.contains(' ') {
		return none
	}
	return FnDecl{name, text[open_index + 1..close_index], text[close_index + 1..].trim_space()}
}

fn c_attribute_symbol(line string) ?string {
	text := line.trim_space()
	if !text.starts_with('@[c:') {
		return none
	}
	first := text.index("'") or { return none }
	last := text.index_after("'", first + 1) or { return none }
	return text[first + 1..last]
}

fn declaration_name(line string, keyword string) ?string {
	mut text := line.trim_space()
	if text.starts_with('pub ') {
		text = text[4..]
	}
	if !text.starts_with(keyword + ' ') || !text.contains('{') {
		return none
	}
	name := text[keyword.len + 1..text.index('{') or { return none }].trim_space()
	if name == '' || name.contains(' ') {
		return none
	}
	return name
}

fn type_alias(line string) ?(string, string) {
	mut text := line.trim_space()
	if text.starts_with('pub ') {
		text = text[4..]
	}
	if !text.starts_with('type ') {
		return none
	}
	eq := text.index('=') or { return none }
	name := text[5..eq].trim_space()
	rhs := text[eq + 1..].trim_space()
	if name == '' || rhs == '' || name.contains(' ') {
		return none
	}
	return name, rhs
}

fn field_decl(line string) ?(string, string) {
	text := line.trim_space()
	if text == '' || text == 'pub mut:' || text.starts_with('@[') {
		return none
	}
	for i, c in text {
		if c.is_space() {
			name := text[..i]
			typ := text[i..].trim_space()
			if name != '' && typ != '' && name.bytes().all(is_ident_byte) {
				return name, typ
			}
			return none
		}
	}
	return none
}

fn remove_c_int_wrappers(s string) string {
	// The translated expressions currently contain only a single, non-nested
	// argument in C.int(...). Keeping the parentheses preserves precedence.
	return s.replace('C.int(', '(')
}

fn replace_qualified_prefix(input string, prefix string) string {
	mut out := []u8{cap: input.len}
	mut i := 0
	for i < input.len {
		mut matches := i + prefix.len <= input.len
		if matches {
			for j := 0; j < prefix.len; j++ {
				if input[i + j] != prefix[j] {
					matches = false
					break
				}
			}
		}
		if matches && (i == 0 || !is_ident_byte(input[i - 1])) {
			i += prefix.len
			continue
		}
		out << input[i]
		i++
	}
	return out.bytestr()
}

fn transform_identifiers(input string, kind string) string {
	mut s := input.replace('main.', '').replace('Main.', '')
	s = remove_c_int_wrappers(s)
	s = s.replace('C.Stbrp_node', 'C.stbrp_node').replace('C.Stbrp_context_opaque', 'C.stbrp_context_opaque')
	s = s.replace('&i8', '&char').replace('& i8', '&char')
	if kind == 'imgui' {
		s = replace_qualified_prefix(s, 'imgui.')
	} else {
		s = replace_qualified_prefix(s, 'implot.')
	}

	mut out := []u8{cap: s.len + 32}
	mut i := 0
	for i < s.len {
		if !is_ident_byte(s[i]) || (s[i] >= `0` && s[i] <= `9`) {
			out << s[i]
			i++
			continue
		}
		start := i
		for i < s.len && is_ident_byte(s[i]) {
			i++
		}
		mut word := s[start..i].clone()
		qualified_c := out.len >= 2 && out[out.len - 2] == `C` && out[out.len - 1] == `.`
		if kind == 'imgui' && word.starts_with('ImGui') && word.len > 5 && starts_upper(word[5..]) {
			word = word[5..]
		}
		if kind == 'implot' && word.starts_with('ImPlot') && word.len > 6 && starts_upper(word[6..]) {
			word = word[6..]
		}
		if !qualified_c {
			if kind == 'imgui' {
				if word.starts_with('ImVector_') || word.starts_with('ImSpan_')
					|| word.starts_with('ImPool_') || word.starts_with('ImChunkStream_')
					|| word.starts_with('ImBitArray_') {
					word = word.replace('ImGui', '')
				}
			} else {
				if word.starts_with('ImVector_') || word.starts_with('ImSpan_')
					|| word.starts_with('ImPool_') || word.starts_with('ImChunkStream_')
					|| word.starts_with('ImBitArray_') {
					word = word.replace('ImPlot', '')
				}
				word = match word {
					'ImU8' { 'u8' }
					'ImU16' { 'u16' }
					'ImU32' { 'u32' }
					'ImU64' { 'u64' }
					'ImS8' { 'i8' }
					'ImS16' { 'i16' }
					'ImS32' { 'i32' }
					'ImS64' { 'i64' }
					'ImWchar16' { 'u16' }
					'ImWchar', 'ImWchar32' { 'u32' }
					'STB_TexteditState' { 'C.STB_TexteditState' }
					'Stbrp_node' { 'C.stbrp_node' }
					'Tm' { 'C.tm' }
					'ID', 'Context', 'ImTextureID' { 'imgui.' + word.replace('ImGui', '') }
					else {
						if word in ['ImVec2', 'ImVec4']
							|| word.starts_with('ImDraw') || word.starts_with('ImFont') {
							'imgui.' + word.replace('ImGui', '')
						} else if word.starts_with('ImGui') && word.len > 5
							&& starts_upper(word[5..]) {
							'imgui.' + word[5..]
						} else {
							word
						}
					}
				}
			}
		}
		out << word.bytes()
	}
	return out.bytestr().replace('imgui.imgui.', 'imgui.')
}

fn clean_type_name(kind string, raw string) string {
	mut name := raw.replace('C.', '').replace('Main.', '')
	if kind == 'imgui' {
		name = name.replace('ImGui', '')
	} else {
		name = name.replace('ImPlot', '')
	}
	return name
}

fn clean_type_expr(kind string, value string) string {
	return transform_identifiers(value, kind)
}

fn clean_line(kind string, line string) string {
	return clean_type_expr(kind, line)
}

fn postprocess_identifiers(input string) string {
	mut out := []u8{cap: input.len + 32}
	mut i := 0
	for i < input.len {
		if !is_ident_byte(input[i]) || input[i].is_digit() {
			out << input[i]
			i++
			continue
		}
		start := i
		i++
		for i < input.len && is_ident_byte(input[i]) {
			i++
		}
		mut word := input[start..i].clone()
		qualified_c := out.len >= 2 && out[out.len - 2] == `C` && out[out.len - 1] == `.`
		if word == 'int' && (i >= input.len || input[i] != `(`) {
			word = 'i32'
		}
		if word == 'va_list' && !qualified_c {
			word = 'Va_list'
		}
		out << word.bytes()
	}
	return out.bytestr().replace('C.int(', '(')
}

fn remove_self_type_prefix(input string, prefix string) string {
	mut out := []u8{cap: input.len}
	mut i := 0
	for i < input.len {
		next := i + prefix.len
		mut matches := next < input.len && input[next] >= `A` && input[next] <= `Z`
		if matches {
			for j := 0; j < prefix.len; j++ {
				if input[i + j] != prefix[j] {
					matches = false
					break
				}
			}
		}
		if matches && (i == 0 || !is_ident_byte(input[i - 1])) {
			i += prefix.len
			continue
		}
		out << input[i]
		i++
	}
	return out.bytestr()
}

fn normalize_alias_rhs(kind string, name string, raw string) string {
	mut rhs := raw
	if rhs == 'int' {
		rhs = 'i32'
	}
	if rhs.starts_with('ImBitArray_') {
		rhs = 'C.' + rhs
	}
	if kind == 'imgui' {
		rhs = match name {
			'ImBitArrayPtr' { '&u32' }
			'ImStbTexteditState' { 'C.STB_TexteditState' }
			'ImBitArrayForNamedKeys' {
				'C.ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN'
			}
			'ImWchar' { 'u32' }
			else {
				match rhs {
					'Stbrp_node' { 'C.stbrp_node' }
					'Stbrp_context_opaque' { 'C.stbrp_context_opaque' }
					else { rhs }
				}
			}
		}
	}
	return rhs
}

fn camel_to_snake(value string) string {
	mut out := []u8{cap: value.len + 8}
	for i, c in value {
		is_upper := c >= `A` && c <= `Z`
		prev_lower_or_digit := i > 0 && (is_lower_byte(value[i - 1]) || is_digit_byte(value[i - 1]))
		next_lower := i + 1 < value.len && value[i + 1] >= `a` && value[i + 1] <= `z`
		prev_upper := i > 0 && value[i - 1] >= `A` && value[i - 1] <= `Z`
		if is_upper && (prev_lower_or_digit || (prev_upper && next_lower)) {
			out << `_`
		}
		out << if is_upper { c + 32 } else { c }
	}
	return out.bytestr()
}

fn snake_to_camel(value string) string {
	mut out := ''
	for part in value.split('_') {
		if part != '' {
			out += part[..1].to_upper() + part[1..]
		}
	}
	return out
}

fn clean_function_name(kind string, raw string) string {
	mut name := raw
	if kind == 'imgui' {
		if name.starts_with('ig_') {
			name = name[3..]
		}
		if name.starts_with('im_gui_') {
			name = name[7..]
		}
		name = name.replace('im_gui_', '')
	} else {
		if name.starts_with('im_plot_') {
			name = name[8..]
		}
		name = name.replace('im_plot_', '')
		if name.starts_with('implot_') {
			name = name[7..]
		}
	}
	return name
}

fn infer_c_symbol(kind string, vname string) string {
	if kind == 'imgui' && (vname.starts_with('im_vec2_') || vname.starts_with('im_vec4_')) {
		return snake_to_camel(vname)
	}
	return if kind == 'imgui' {
		'ig' + snake_to_camel(vname)
	} else {
		'ImPlot' + snake_to_camel(vname)
	}
}

fn parameter_parts(text string) ?(bool, string, string) {
	mut p := text.trim_space()
	mut is_mut := false
	if p.starts_with('mut ') {
		is_mut = true
		p = p[4..]
	}
	for i, c in p {
		if c.is_space() {
			name := p[..i].clone()
			typ := p[i..].trim_space()
			if name != '' && typ != '' && name.bytes().all(is_ident_byte) {
				return is_mut, name, typ
			}
			return none
		}
	}
	return none
}

fn emit_function(ctx CleanupContext, csym string, decl FnDecl) string {
	mut ret := clean_type_expr(ctx.kind, decl.ret).trim_space()
	vname := clean_function_name(ctx.kind, decl.name)
	mut vparts := []string{}
	mut cparts := []string{}
	mut args := []string{}
	for raw in split_top_level_commas(decl.params) {
		p := raw.trim_space()
		if p == '' || p == '...' || p.starts_with('vargs ') {
			continue
		}
		is_mut, raw_name, raw_type := parameter_parts(p) or { continue }
		mut name := raw_name
		typ := clean_type_expr(ctx.kind, raw_type).replace('& i8', '&char').replace('&i8', '&char')
		fallback_const := typ == '&char' && name in ['fmt', 'text', 'text_end', 'label', 'str',
			'str_id', 'overlay', 'shortcut', 'name', 'begin', 'end', 'fmt_begin', 'fmt_end']
		if (ctx.const_params['${csym}\x00${name}'] || fallback_const) && !name.starts_with('const_') {
			name = 'const_' + name
		}
		vparts << (if is_mut { 'mut ' } else { '' }) + '${name} ${typ}'
		if is_mut {
			cparts << 'mut_${name} ${typ}'
			args << 'mut_${name}'
		} else {
			cparts << '${name} ${typ}'
			args << name
		}
	}
	call := 'C.${csym}(${args.join(', ')})'
	mut result := '\n@[keep_args_alive]\nfn C.${csym}(${cparts.join(', ')})'
	if ret != '' {
		result += ' ${ret}'
	}
	result += '\n\n@[inline]\npub fn ${vname}(${vparts.join(', ')})'
	if ret != '' {
		result += ' ${ret}'
	}
	result += ' {\n'
	result += if ret == '' { '\t${call}\n' } else { '\treturn ${call}\n' }
	return result + '}'
}

fn emit_struct(kind string, original string, clean string, body []string) string {
	mut c_name := original.replace('C.', '')
	if c_name == 'Stbrp_node' {
		c_name = 'stbrp_node'
	}
	if c_name == 'Stbrp_context_opaque' {
		c_name = 'stbrp_context_opaque'
	}
	if clean == '' || clean.contains('.') {
		return ''
	}
	mut fields := []string{}
	for raw in body {
		// Apply cleanup to the translated line and then to its isolated type,
		// matching the established handling of aliases such as ImS8 -> i8 -> char.
		field, typ := field_decl(clean_line(kind, raw)) or { continue }
		mut field_name := field
		if c_name !in ['ImVec2', 'ImVec4', 'ImVec2_c', 'ImVec2i_c', 'ImVec2ih', 'ImVec4_c',
			'ImDrawVert'] {
			field_name = field[..1].to_upper() + field[1..]
		}
		fields << '\t${field_name} ${clean_type_expr(kind, typ)}'
	}
	mut result := '\n\npub type ${clean} = C.${c_name}\n@[typedef]\npub struct C.${c_name} {'
	if fields.len == 0 {
		return result + '}'
	}
	return result + '\npub mut:\n' + fields.join('\n') + '\n}'
}

fn enum_member_prefix(original string) string {
	return camel_to_snake(without_suffix(original, '_')) + '_'
}

fn clean_enum_member_name(ctx CleanupContext, raw string, prefix string) string {
	mut name := raw
	if name.starts_with(ctx.cfg.lower) {
		name = name[ctx.cfg.lower.len..]
	}
	if name.starts_with(prefix) {
		name = name[prefix.len..]
	}
	mut shorter := prefix
	if shorter.starts_with(ctx.cfg.lower) {
		shorter = shorter[ctx.cfg.lower.len..]
	}
	if name.starts_with(shorter) {
		name = name[shorter.len..]
	}
	private_prefix := without_suffix(shorter, 'private_')
	if private_prefix != shorter && name.starts_with(private_prefix) {
		name = name[private_prefix.len..]
	}
	if ctx.kind == 'imgui' && name.starts_with('im_gui_') {
		name = name[7..]
	}
	if ctx.kind == 'implot' && name.starts_with('im_plot_') {
		name = name[8..]
	}
	if shorter.ends_with('key_') && name.starts_with('key_') {
		name = name[4..]
	}
	return name
}

fn numeric_to_bits(value i64) string {
	if value == 0 {
		return '0'
	}
	mut bits := []string{}
	mut current := value
	mut bit := 0
	for current > 0 {
		if current & 1 == 1 { bits << '1 << ${bit}' }
		current >>= 1
		bit++
	}
	return bits.join(' | ')
}

fn tokenize_expr(input string) ?[]string {
	mut tokens := []string{}
	mut i := 0
	for i < input.len {
		c := input[i]
		if c.is_space() {
			i++
			continue
		}
		if c >= `0` && c <= `9` {
			start := i
			i++
			if c == `0` && i < input.len && (input[i] == `x` || input[i] == `X`) {
				i++
				for i < input.len && (input[i].is_hex_digit()) {
					i++
				}
			} else {
				for i < input.len && input[i] >= `0` && input[i] <= `9` {
					i++
				}
			}
			tokens << input[start..i]
			continue
		}
		if is_ident_byte(c) && !(c >= `0` && c <= `9`) {
			start := i
			i++
			for i < input.len && is_ident_byte(input[i]) {
				i++
			}
			tokens << input[start..i]
			continue
		}
		if i + 1 < input.len && input[i..i + 2] in ['<<', '>>'] {
			tokens << input[i..i + 2]
			i += 2
			continue
		}
		if c.ascii_str() in ['+', '-', '*', '/', '|', '&', '~', '^', '(', ')'] {
			tokens << c.ascii_str()
			i++
			continue
		}
		return none
	}
	return tokens
}

fn (mut p ExprParser) take(value string) bool {
	if p.pos < p.tokens.len && p.tokens[p.pos] == value {
		p.pos++
		return true
	}
	return false
}

fn (mut p ExprParser) primary() !i64 {
	if p.take('(') {
		value := p.bit_or()!
		if !p.take(')') {
			return error('missing closing parenthesis')
		}
		return value
	}
	if p.pos >= p.tokens.len {
		return error('missing value')
	}
	token := p.tokens[p.pos]
	p.pos++
	if token.starts_with('0x') || token.starts_with('0X') {
		return i64(token[2..].parse_uint(16, 64)!)
	}
	if token[0].is_digit() {
		return token.i64()
	}
	if token in p.known {
		return p.known[token]
	}
	return error('unknown identifier ${token}')
}

fn (mut p ExprParser) unary() !i64 {
	if p.take('~') {
		return ~p.unary()!
	}
	if p.take('-') {
		return -p.unary()!
	}
	if p.take('+') {
		return p.unary()!
	}
	return p.primary()
}

fn (mut p ExprParser) product() !i64 {
	mut value := p.unary()!
	for p.pos < p.tokens.len {
		op := p.tokens[p.pos]
		if op !in ['*', '/'] {
			break
		}
		p.pos++
		rhs := p.unary()!
		value = if op == '*' { value * rhs } else { value / rhs }
	}
	return value
}

fn (mut p ExprParser) sum() !i64 {
	mut value := p.product()!
	for p.pos < p.tokens.len {
		op := p.tokens[p.pos]
		if op !in ['+', '-'] {
			break
		}
		p.pos++
		rhs := p.product()!
		value = if op == '+' { value + rhs } else { value - rhs }
	}
	return value
}

fn (mut p ExprParser) shift() !i64 {
	mut value := p.sum()!
	for p.pos < p.tokens.len {
		op := p.tokens[p.pos]
		if op !in ['<<', '>>'] {
			break
		}
		p.pos++
		rhs := p.sum()!
		value = if op == '<<' { i64(u64(value) << u64(rhs)) } else { i64(u64(value) >> u64(rhs)) }
	}
	return value
}

fn (mut p ExprParser) bit_and() !i64 {
	mut value := p.shift()!
	for p.take('&') {
		value &= p.shift()!
	}
	return value
}

fn (mut p ExprParser) bit_xor() !i64 {
	mut value := p.bit_and()!
	for p.take('^') {
		value ^= p.bit_and()!
	}
	return value
}

fn (mut p ExprParser) bit_or() !i64 {
	mut value := p.bit_xor()!
	for p.take('|') {
		value |= p.bit_xor()!
	}
	return value
}

fn eval_enum_value(expr string, known map[string]i64) ?i64 {
	mut clean := strip_line_comment(expr)
	if start := clean.index('/*') {
		if end := clean.index_after('*/', start + 2) {
			clean = clean[..start] + clean[end + 2..]
		}
	}
	clean = clean.replace('C.int(', '(').replace('u32(', '(').replace('i32(', '(').replace('int(', '(')
	tokens := tokenize_expr(clean) or { return none }
	mut parser := ExprParser{ tokens: tokens, known: known }
	value := parser.bit_or() or { return none }
	if parser.pos != tokens.len {
		return none
	}
	return value
}

fn emit_enum(ctx CleanupContext, clean_name string, original string, body []string) string {
	prefix := enum_member_prefix(original)
	mut members := []string{}
	mut seen_values := map[i64]bool{}
	mut known := map[string]i64{}
	mut next_auto := i64(0)
	for raw in body {
		text := raw.trim_space()
		if text == '' || text.starts_with('//') {
			continue
		}
		mut raw_name := text
		mut expr := ''
		if eq := text.index('=') {
			raw_name = text[..eq].trim_space()
			expr = text[eq + 1..].trim_space()
		}
		if raw_name == '' || !raw_name.bytes().all(is_ident_byte) {
			continue
		}
		mut name := clean_enum_member_name(ctx, raw_name, prefix)
		if name == '' {
			continue
		}
		if name[0].is_digit() {
			name = '_' + name
		}
		mut value := ?i64(none)
		if expr != '' {
			expr = clean_line(ctx.kind, expr).trim_space()
			if clean_name.contains('Flags') && expr.bytes().all(fn (c u8) bool {
				return c.is_digit()
			}) {
				expr = numeric_to_bits(expr.i64())
			}
			value = eval_enum_value(expr, known)
			if current := value {
				next_auto = current + 1
			}
		} else {
			value = next_auto
			next_auto++
		}
		duplicate := if current := value { seen_values[current] } else { false }
		if expr != '' {
			members << if duplicate { ' //${name} = ${expr}' } else { ' ${name:-34} = ${expr}' }
		} else {
			members << if duplicate { ' //${name}' } else { ' ${name}' }
		}
		if current := value {
			known[name] = current
			if !duplicate {
				seen_values[current] = true
			}
		}
	}
	return '\npub enum ${clean_name} {\n' + members.join('\n') + '\n}'
}

fn parse_const_params(header string) map[string]bool {
	mut result := map[string]bool{}
	for raw in header.split_into_lines() {
		line := strip_line_comment(raw).trim_space()
		// Preserve the established generator behavior: ImPlot's API macro is
		// inspected here, while cimgui const naming continues to use the small
		// stable fallback list in emit_function.
		if !(line.starts_with('IMGUI_API ') || line.starts_with('IMPLOT_API '))
			|| !line.ends_with(';') {
			continue
		}
		open_index := line.index('(') or { continue }
		close_index := line.last_index(')') or { continue }
		if close_index < open_index {
			continue
		}
		before := line[..open_index].trim_space()
		symbol := before.all_after_last(' ')
		for raw_param in split_top_level_commas(line[open_index + 1..close_index]) {
			param := raw_param.trim_space()
			if !param.contains('const') {
				continue
			}
			without_array := if bracket := param.index('[') { param[..bracket] } else { param }
			name := without_array.trim_space().all_after_last(' ').trim_left('*')
			if name != '' {
				result['${symbol}\x00${name}'] = true
			}
		}
	}
	return result
}

fn skip_line(line string) bool {
	text := line.trim_space()
	if text == '@[translated]' || text in ['module main', 'module imgui', 'module implot'] {
		return true
	}
	if text.starts_with('// This file is automatically generated by') || text.starts_with('// based on')
		|| text.starts_with('// with ') || text.starts_with('// typedef ')
		|| text.starts_with('// CIMGUI_DEFINE_ENUMS_AND_STRUCTS') || text.starts_with('// namespace') {
		return true
	}
	if text.starts_with('#') || text.starts_with('typedef ') {
		return true
	}
	if text.starts_with('struct ') && text.ends_with(';') && !text.contains('{') {
		return true
	}
	if text.ends_with(';') && !text.contains(' ') {
		return true
	}
	return false
}

fn parse_version(src string, header string, kind string) (string, string) {
	if kind == 'implot' {
		version_header := os.read_file(os.join_path(@DIR, 'include', 'implot', 'implot.h')) or { '' }
		mut version := ''
		mut number := ''
		for raw in version_header.split_into_lines() {
			line := raw.trim_space()
			if line.starts_with('#define IMPLOT_VERSION "') {
				version = line.trim_string_left('#define IMPLOT_VERSION ').trim('"')
			}
			if line.starts_with('#define IMPLOT_VERSION_NUM ') {
				number = line.all_after_last(' ')
			}
		}
		if version != '' {
			return version, number
		}
	}
	for raw in src.split_into_lines() {
		if raw.contains('file version "') {
			rest := raw.all_after('file version "')
			version := rest.all_before('"')
			number := rest.all_after('"').trim_space().all_before(' ')
			return version, number
		}
	}
	macro := if kind == 'imgui' { 'IMGUI' } else { 'IMPLOT' }
	mut version := ''
	mut number := ''
	for raw in header.split_into_lines() {
		line := raw.trim_space()
		if line.starts_with('#define ${macro}_VERSION "') {
			version = line.trim_string_left('#define ${macro}_VERSION ').trim('"')
		}
		if line.starts_with('#define ${macro}_VERSION_NUM ') {
			number = line.all_after_last(' ')
		}
	}
	return version, number
}

fn cleanup_notes() string {
	return '/*
cleanup_imgui_implot.vsh non-regression notes

Keep this block current when changing cleanup rules. Do not hardcode one
function, enum member, or struct member; derive facts from cimgui/cimgui.h or
cimplot/cimplot.h, then apply generic V cleanup.

Covered cases and examples:
1. Strip raw C/preprocessor leakage:
     #ifdef CIMGUI_DEFINE_ENUMS_AND_STRUCTS
     typedef struct ImDrawChannel;
     struct ImDrawChannel;
     typedef ImColor;
   Callback typedef parsing is line-based so it never recreates:
     broken callback alias with unsigned __int64 ImU64 payload
2. Const parameter names come from header prototypes:
     CIMGUI_API bool igButton(const char* label,const ImVec2_c size);
   This yields const_label/const_size generically.
3. Missing aliases/opaque declarations are inferred from type positions and
   header typedefs only, not arbitrary capitalized field names.
4. Value backing structs such as ImVec2_c/ImVec4_c/ImColor_c/ImRect_c back public
   aliases ImVec2/ImVec4/ImColor/ImRect. Do not emit duplicate empty C structs.
   Vector fields remain lowercase x/y/z/w for V literals.
5. Remove self-module prefixes: imgui.v must not refer to imgui.Type; implot.v
   must not refer to implot.Type, because each file is already inside that module.
6. STB rectpack names are intentionally preserved from C when c2v title-cases
   lower-case C identifiers in aliases like:
     example: `pub type Stbrp_node_im = Stbrp_node`
   Normalize those references to C.stbrp_node/C.stbrp_context_opaque and emit
   their C-backed declarations with the identifiers used by the headers.
7. Enum aliases are handled dynamically, never by member-name lists. V enums
   reject duplicate integer values, while C/C++ enums often define aliases:
     any_popup = 1 << 10 | 1 << 11
     mouse_button_shift_ = 1 << 1
     mouse_button_mask_ = 1 << 2 | 1 << 3
     another_alias = 12
   The cleanup evaluates safe integer enum expressions as it emits each enum;
   if a value was already emitted earlier in the same enum, the later member
   is commented out. This prevents regressions such as `enum value 12 already
   exists` without hardcoding a specific enum or member name.
*/

'
}

fn header_text(ctx CleanupContext, version string, number string) string {
	imports := if ctx.kind == 'implot' {
		'\n\nimport antono2.imgui\n// C.tm is used by translated callback signatures. Keep the import explicitly.\nimport time as _'
	} else {
		''
	}
	mut result := 'module ${ctx.cfg.module_name}${imports}\n\n' + cleanup_notes()
	result += '/*
MIT License

Copyright (c) 2025-2026 Anton Oreskin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/


'
	if version != '' {
		result += "pub const version = '${version}'\n"
	}
	if number != '' {
		result += 'pub const version_num = ${number}\n'
	}
	return result + '\n'
}

fn parse_imported_imgui(path string) (map[string]bool, map[string]string, map[string]bool) {
	mut structs := map[string]bool{}
	mut aliases := map[string]string{}
	mut types := map[string]bool{}
	source := os.read_file(path) or { return structs, aliases, types }
	lines := source.split_into_lines()
	for line in lines {
		text := line.trim_space()
		if text.starts_with('pub struct C.') {
			name := before_or_self(before_or_self(text[13..], ' '), '{')
			if name != '' {
				structs[name] = true
			}
		}
		if name, rhs := type_alias(text) {
			if rhs.starts_with('C.') && !rhs.contains(' ') {
				aliases[rhs[2..]] = name
			}
			types[name] = true
		}
		if text.starts_with('pub struct ') || text.starts_with('pub enum ') {
			parts := text.split(' ')
			if parts.len >= 3 {
				types[parts[2].all_before('{')] = true
			}
		}
	}
	return structs, aliases, types
}

fn find_imgui_binding(output string) !string {
	dir := os.dir(output)
	for candidate in [os.join_path(@DIR, 'imgui.v'), os.join_path(dir, '..', 'imgui.v'),
		os.join_path(dir, '..', 'src', 'imgui.v')] {
		if os.is_file(candidate) {
			return candidate
		}
	}
	return error('cannot deduplicate ImPlot declarations: imgui.v was not found')
}

fn extract_identifiers(value string) []string {
	mut result := []string{}
	mut i := 0
	for i < value.len {
		if !is_ident_byte(value[i]) || value[i].is_digit() {
			i++
			continue
		}
		start := i
		i++
		for i < value.len && is_ident_byte(value[i]) {
			i++
		}
		if starts_upper(value[start..i]) {
			preceded_by_dot := start > 0 && value[start - 1] == `.`
			followed_by_dot := i < value.len && value[i] == `.`
			if !preceded_by_dot && !followed_by_dot { result << value[start..i] }
		}
	}
	return result
}

fn parse_header_type_names(ctx CleanupContext) map[string]string {
	mut result := map[string]string{}
	for raw in ctx.header.split_into_lines() {
		line := strip_line_comment(raw).trim_space()
		if line.contains('{') || line.contains('}') {
			continue
		}
		if line.starts_with('typedef ') && line.ends_with(';') && !line.contains('(*') {
			body := line[8..line.len - 1].trim_space()
			public := body.all_after_last(' ')
			mut backing := public
			left := body[..body.len - public.len].trim_space()
			if left.starts_with('struct ') && !left[7..].contains(' ') {
				backing = left[7..]
			}
			name := clean_type_name(ctx.kind, public)
			if name != '' && (name !in result || backing.ends_with('_c')) {
				result[name] = backing
			}
		}
		mut rest := line
		for {
			mut index := -1
			mut keyword_len := 0
			for keyword in ['struct ', 'class '] {
				if current := rest.index(keyword) {
					if index == -1 || current < index {
						index = current
						keyword_len = keyword.len
					}
				}
			}
			if index < 0 {
				break
			}
			name_text := rest[index + keyword_len..].clone()
			mut end := 0
			for end < name_text.len && is_ident_byte(name_text[end]) {
				end++
			}
			if end > 0 {
				c_name := name_text[..end]
				name := clean_type_name(ctx.kind, c_name)
				if name != '' && name !in result {
					result[name] = c_name
				}
			}
			rest = name_text[if end > 0 { end } else { 1 }..]
		}
	}
	return result
}

fn c_type_to_v(kind string, raw string) string {
	mut text := raw.trim_space()
	if start := text.index('struct ') {
		if open := text.index_after('{', start) {
			if close := text.index_after('}', open + 1) {
				text = text[..start] + text[close + 1..]
			}
		}
	}
	text = text.replace('const', '').trim_space()
	ptr := text.contains('*')
	text = text.replace('*', ' ').fields().join(' ')
	parts := text.fields()
	if parts.len == 2 && parts[0] == parts[1] {
		text = parts[0]
	}
	if text.ends_with('_c') {
		text = without_suffix(text, '_c')
	}
	base := match text {
		'void' { '' }
		'bool' { 'bool' }
		'int' { 'i32' }
		'float' { 'f32' }
		'double' { 'f64' }
		'char' { 'char' }
		'unsigned int' { 'u32' }
		'unsigned char' { 'u8' }
		'size_t' { 'usize' }
		else { clean_type_name(kind, text) }
	}
	return (if ptr { '&' } else { '' }) + (if base == '' && ptr { 'voidptr' } else { base })
}

fn parse_callback_typedefs(ctx CleanupContext) map[string]string {
	mut result := map[string]string{}
	for raw in ctx.header.split_into_lines() {
		mut line := strip_line_comment(raw)
		for {
			start := line.index('/*') or { break }
			end := line.index_after('*/', start + 2) or { break }
			line = line[..start] + line[end + 2..]
		}
		line = line.trim_space()
		if !line.starts_with('typedef ') || !line.ends_with(';') {
			continue
		}
		marker := line.index('(*') or { continue }
		close_name := line.index_after(')', marker + 2) or { continue }
		open_params := line.index_after('(', close_name + 1) or { continue }
		close_params := line.last_index(')') or { continue }
		if close_params < open_params {
			continue
		}
		ret := line[8..marker].trim_space()
		c_name := line[marker + 2..close_name].trim_space()
		params := line[open_params + 1..close_params].clone()
		if ret.contains_any('#;{}') || params.contains_any('#;{}') {
			continue
		}
		name := clean_type_name(ctx.kind, c_name)
		if name == '' {
			continue
		}
		mut vparams := []string{}
		for raw_param in split_top_level_commas(params) {
			mut param := raw_param.trim_space()
			if param == '' || param == 'void' {
				continue
			}
			if bracket := param.index('[') {
				param = param[..bracket]
			}
			fields := param.fields()
			if fields.len > 1 {
				last := fields.last()
				if last.trim_left('*').bytes().all(is_ident_byte) {
					param = fields[..fields.len - 1].join(' ') + if last.starts_with('*') {
						'*'
					} else {
						''
					}
				}
			}
			vparams << c_type_to_v(ctx.kind, param)
		}
		vret := c_type_to_v(ctx.kind, ret)
		result[name] = 'pub type ${name} = fn (${vparams.join(', ')})' + if vret != '' {
			' ${vret}'
		} else {
			''
		}
	}
	return result
}

fn defined_types(body string) map[string]bool {
	mut result := map[string]bool{}
	for line in body.split_into_lines() {
		text := line.trim_space()
		if name, _ := type_alias(text) {
			result[name] = true
		}
		for prefix in ['pub struct ', 'struct ', 'pub enum ', 'enum '] {
			if text.starts_with(prefix) {
				name := before_or_self(before_or_self(text[prefix.len..], ' '), '{')
				if name != '' && !name.starts_with('C.') {
					result[name] = true
				}
			}
		}
	}
	return result
}

fn dynamic_missing_decls(ctx CleanupContext, body string, imported_structs map[string]bool,
	imported_aliases map[string]string, imported_types map[string]bool) string {
	mut defined := defined_types(body)
	builtin := ['bool', 'char', 'string', 'voidptr', 'byte', 'rune', 'int', 'i8', 'u8', 'i16', 'u16',
		'i32', 'u32', 'i64', 'u64', 'f32', 'f64', 'usize', 'isize', 'none', 'true', 'false', 'C']
	mut need := map[string]bool{}
	for line in body.split_into_lines() {
		text := line.trim_space()
		mut expressions := []string{}
		if _, rhs := type_alias(text) {
			expressions << rhs
		} else if decl := parse_fn(text) {
			for raw_param in split_top_level_commas(decl.params) {
				if _, _, typ := parameter_parts(raw_param) { expressions << typ }
			}
			expressions << decl.ret
		} else if line.len > 0 && line[0].is_space() {
			if _, typ := field_decl(line) { expressions << typ }
		}
		for expression in expressions {
			for name in extract_identifiers(expression) {
				if name !in builtin && name !in defined {
					need[name] = true
				}
			}
		}
	}
	if (body.contains('va_list') || body.contains('Va_list')) && 'Va_list' !in defined {
		need['Va_list'] = true
	}

	mut c_suffix := map[string]string{}
	mut need_c := map[string]bool{}
	for line in body.split_into_lines() {
		text := line.trim_space()
		if name, rhs := type_alias(text) {
			if name.ends_with('_c') && rhs.starts_with('C.') && rhs.ends_with('_c') {
				c_suffix[without_suffix(name, '_c')] = rhs[2..]
			}
			if rhs.starts_with('C.') {
				need_c[before_or_self(rhs, ' ').trim_string_right('*&')] = true
			}
		}
	}
	// Remove backing types only after collecting every alias. A public alias can
	// appear later than its C struct in c2v output.
	for line in body.split_into_lines() {
		text := line.trim_space()
		if text.starts_with('pub struct C.') {
			name := before_or_self(before_or_self(text[13..], ' '), '{')
			if name.ends_with('_c') {
				c_suffix[without_suffix(name, '_c')] = name
			}
			need_c.delete('C.' + name)
		}
	}
	callbacks := parse_callback_typedefs(ctx)
	header_types := parse_header_type_names(ctx)
	mut decls := []string{}
	mut names := need.keys()
	names.sort()
	for name in names {
		if name in defined {
			continue
		}
		if imported_types[name] {
			decls << 'pub type ${name} = imgui.${name}'
			defined[name] = true
			continue
		}
		if name in imported_aliases {
			decls << 'pub type ${name} = imgui.${imported_aliases[name]}'
			defined[name] = true
			continue
		}
		if name == 'Va_list' {
			decls << if imported_structs['va_list'] {
				'pub type Va_list = imgui.Va_list'
			} else {
				'pub type Va_list = C.va_list\n@[typedef]\npub struct C.va_list {}'
			}
			defined[name] = true
			need_c.delete('C.va_list')
			continue
		}
		if ctx.kind == 'imgui' && name == 'ImWchar' {
			decls << 'pub type ImWchar = u32'
			defined[name] = true
			continue
		}
		if name in c_suffix {
			decls << 'pub type ${name} = C.${c_suffix[name]}'
			defined[name] = true
			need_c.delete('C.' + c_suffix[name])
			continue
		}
		if name in callbacks {
			decls << callbacks[name]
			defined[name] = true
			continue
		}
		if name.ends_with('Callback') {
			target := without_suffix(name, 'Callback') + 'CallbackData'
			decls << 'pub type ${name} = fn (&${target})' + if name == 'InputTextCallback' {
				' i32'
			} else {
				''
			}
			defined[name] = true
			continue
		}
		if name !in header_types {
			continue
		}
		c_name := header_types[name]
		decls << 'pub type ${name} = C.${c_name}\n@[typedef]\npub struct C.${c_name} {}'
		defined[name] = true
		need_c.delete('C.' + c_name)
	}
	mut c_names := need_c.keys()
	c_names.sort()
	for c_type in c_names {
		if c_type in ['C.int', 'C.float', 'C.double', 'C.char', 'C.bool', 'C.void'] {
			continue
		}
		c_name := without_prefix(c_type, 'C.')
		if imported_structs[c_name] {
			continue
		}
		decls << '@[typedef]\npub struct ${c_type} {}'
	}
	return if decls.len > 0 { decls.join('\n\n') + '\n\n' } else { '' }
}

fn postprocess(kind string, input string) string {
	mut lines := input.split_into_lines()
	mut out := []string{cap: lines.len}
	mut index := 0
	for index < lines.len {
		mut line := postprocess_identifiers(lines[index])
		text := line.trim_space()
		if text.starts_with("@[export: '") && index + 1 < lines.len && lines[index + 1].trim_space().starts_with('const ') {
			line = 'pub ' + lines[index + 1].trim_space()
			index++
		}
		if line.trim_space().starts_with('const ') || line.trim_space().starts_with('pub const ') {
			prefix := if line.trim_space().starts_with('pub const ') {
				'pub const '
			} else {
				'const '
			}
			rest := line.trim_space()[prefix.len..]
			name := rest.all_before(' ')
			if name != '' && name.bytes().all(fn (c u8) bool {
				return c == `_` || c.is_digit() || (c >= `A` && c <= `Z`)
			}) {
				line = prefix + name.to_lower() + rest[name.len..]
			}
		}
		if line.trim_space().starts_with('__global GImGui') {
			line = '//' + line
		}
		if !skip_line(line) || line.trim_space().starts_with('module ') { out << line }
		index++
	}
	mut result := out.join('\n') + '\n'
	if kind == 'imgui' && result.contains('pub type ImStbTexteditState = C.STB_TexteditState\n')
		&& !result.contains('pub type ImStbTexteditState = C.STB_TexteditState\n@[typedef]') {
		result = result.replace('pub type ImStbTexteditState = C.STB_TexteditState\n', 'pub type ImStbTexteditState = C.STB_TexteditState\n@[typedef]\npub struct C.STB_TexteditState {}\n\n')
	}
	for result.contains('\n\n\n\n') {
		result = result.replace('\n\n\n\n', '\n\n\n')
	}
	return result
}

fn replace_struct_block(input string, c_name string, replacement string) string {
	needle := 'pub struct C.${c_name} {'
	start := input.index(needle) or { return input }
	line_end := input.index_after('\n', start) or { input.len }
	first_line := input[start..line_end]
	if first_line.contains('}') {
		cursor := if line_end < input.len { line_end + 1 } else { line_end }
		return input[..start] + replacement + '\n' + input[cursor..]
	}
	mut depth := 1
	mut cursor := line_end + 1
	for cursor < input.len && depth > 0 {
		next := input.index_after('\n', cursor) or { input.len }
		line := input[cursor..next].trim_space()
		if line.ends_with('{') { depth++ }
		if line == '}' { depth-- }
		cursor = if next < input.len { next + 1 } else { next }
	}
	return input[..start] + replacement + '\n' + input[cursor..]
}

fn final_sanitize(kind string, input string) string {
	mut s := input.replace('unsigned __int64 ImU64', 'u64').replace('unsigned long long ImU64', 'u64').replace('unsigned long ImU64', 'u64')
	mut public_c := map[string]bool{}
	for line in s.split_into_lines() {
		text := line.trim_space()
		if text.starts_with('pub struct C.') {
			public_c[before_or_self(before_or_self(text[13..], ' '), '{')] = true
		}
	}
	mut lines := []string{}
	mut seen_types := map[string]bool{}
	for line in s.split_into_lines() {
		text := line.trim_space()
		if text.starts_with('struct C.') && text.ends_with('{}') {
			name := text[9..].all_before(' ')
			if public_c[name] {
				continue
			}
		}
		if name, _ := type_alias(text) {
			if seen_types[name] {
				continue
			}
			seen_types[name] = true
		}
		if !skip_line(line) || line.trim_space().starts_with('module ') { lines << line }
	}
	s = lines.join('\n') + '\n'
	for base in ['ImVec2', 'ImVec2i', 'ImVec4', 'ImColor', 'ImRect'] {
		if s.contains('pub type ${base}_c = C.${base}_c') || s.contains('pub struct C.${base}_c') {
			for line in s.split_into_lines() {
				if line.starts_with('pub type ${base} = ') {
					s = s.replace(line, 'pub type ${base} = C.${base}_c')
					break
				}
			}
		}
	}
	s = replace_struct_block(s, 'ImVec2_c', 'pub struct C.ImVec2_c {\npub mut:\n\tx f32\n\ty f32\n}')
	s = replace_struct_block(s, 'ImVec2i_c', 'pub struct C.ImVec2i_c {\npub mut:\n\tx int\n\ty int\n}')
	s = replace_struct_block(s, 'ImVec2ih', 'pub struct C.ImVec2ih {\npub mut:\n\tx i16\n\ty i16\n}')
	s = replace_struct_block(s, 'ImVec4_c', 'pub struct C.ImVec4_c {\npub mut:\n\tx f32\n\ty f32\n\tz f32\n\tw f32\n}')
	if kind == 'imgui' {
		s = remove_self_type_prefix(s, 'imgui.')
	}
	if kind == 'implot' {
		s = remove_self_type_prefix(s, 'implot.')
	}
	for s.contains('\n\n\n\n') {
		s = s.replace('\n\n\n\n', '\n\n\n')
	}
	return s
}

fn header_alias_decls(ctx CleanupContext, body string) string {
	mut defined := defined_types(body)
	mut body_structs := map[string]bool{}
	for line in body.split_into_lines() {
		text := line.trim_space()
		if text.starts_with('pub struct C.') {
			body_structs[before_or_self(before_or_self(text[13..], ' '), '{')] = true
		}
	}
	referenced := extract_identifiers(body)
	mut referenced_map := map[string]bool{}
	for name in referenced {
		referenced_map[name] = true
	}
	mut decls := []string{}
	for raw in ctx.header.split_into_lines() {
		line := strip_line_comment(raw).trim_space()
		if !line.starts_with('typedef struct ') || !line.ends_with(';') {
			continue
		}
		parts := without_suffix(line, ';').fields()
		if parts.len != 4 {
			continue
		}
		backing := parts[2]
		public := parts[3]
		alias := clean_type_name(ctx.kind, public)
		if alias == '' || !starts_upper(alias) || alias in defined {
			continue
		}
		if !referenced_map[alias] && !body_structs[backing] {
			continue
		}
		decls << 'pub type ${alias} = C.${backing}'
		if !body_structs[backing] {
			decls << '@[typedef]\npub struct C.${backing} {}'
			body_structs[backing] = true
		}
		defined[alias] = true
	}
	return if decls.len > 0 { decls.join('\n') + '\n\n' } else { '' }
}

fn missing_c_alias_target_decls(body string, imported map[string]bool) string {
	mut declared := map[string]bool{}
	mut missing := map[string]bool{}
	for line in body.split_into_lines() {
		text := line.trim_space()
		if text.starts_with('pub struct C.') {
			declared[before_or_self(before_or_self(text[13..], ' '), '{')] = true
		}
	}
	for line in body.split_into_lines() {
		if _, rhs := type_alias(line) {
			if rhs.starts_with('C.') && !rhs.contains(' ') {
				name := rhs[2..]
				if !declared[name] && !imported[name] {
					missing[name] = true
				}
			}
		}
	}
	mut names := missing.keys()
	names.sort()
	mut result := ''
	for name in names {
		result += '@[typedef]\npub struct C.${name} {}\n\n'
	}
	return result
}

fn insert_after_version(input string, addition string) string {
	if addition == '' {
		return input
	}
	needle := 'pub const version_num'
	start := input.index(needle) or { return input }
	line_end := input.index_after('\n', start) or { return input }
	mut after := line_end + 1
	if after < input.len && input[after] == `\n` { after++ }
	return input[..after] + addition + input[after..]
}

fn clean_one(kind string, input_path string, output_path string) ! {
	cfg := config_for(kind)!
	source := os.read_file(input_path)!
	header_path := os.join_path(@DIR, 'include', if kind == 'imgui' {
		'cimgui.h'
	} else {
		'cimplot.h'
	})
	header := os.read_file(header_path)!
	ctx := CleanupContext{kind, cfg, header, parse_const_params(header)}
	version, number := parse_version(source, header, kind)

	mut imported_structs := map[string]bool{}
	mut imported_aliases := map[string]string{}
	mut imported_types := map[string]bool{}
	if kind == 'implot' {
		imgui_path := find_imgui_binding(output_path)!
		imported_structs, imported_aliases, imported_types = parse_imported_imgui(imgui_path)
	}

	lines := source.replace('\r\n', '\n').split_into_lines()
	mut out := []string{}
	mut seen_type := map[string]bool{}
	mut seen_struct := map[string]bool{}
	mut seen_enum := map[string]bool{}
	mut index := 0
	for index < lines.len {
		line := lines[index]
		if skip_line(line) {
			index++
			continue
		}
		if csym := c_attribute_symbol(line) {
			for index + 1 < lines.len && lines[index + 1].trim_space().starts_with('@[') {
				index++
			}
			if index + 1 < lines.len {
				if decl := parse_fn(lines[index + 1]) {
					index++
					if !(kind == 'implot' && (csym.starts_with('ig') || csym.starts_with('ImGui'))) {
						out << emit_function(ctx, csym, decl)
					}
				}
			}
			index++
			continue
		}
		if decl := parse_fn(line) {
			if !(kind == 'implot' && decl.name.starts_with('im_gui_')) {
				out << emit_function(ctx, infer_c_symbol(kind, decl.name), decl)
			}
			index++
			continue
		}
		if original := declaration_name(line, 'enum') {
			mut body := []string{}
			index++
			for index < lines.len && lines[index].trim_space() != '}' {
				body << lines[index]
				index++
			}
			clean := clean_type_name(kind, without_suffix(original, '_')) + if original.ends_with('_') {
				'_'
			} else {
				''
			}
			if !seen_enum[clean] {
				seen_enum[clean] = true
				out << emit_enum(ctx, clean, original, body)
			}
			index++
			continue
		}
		if original := declaration_name(line, 'struct') {
			mut body := []string{}
			if !line.trim_space().ends_with('{}') {
				index++
				for index < lines.len && lines[index].trim_space() != '}' {
					body << lines[index]
					index++
				}
			}
			if kind == 'implot' && (original.starts_with('imgui.') || original.starts_with('ImGui')) {
				index++
				continue
			}
			clean := clean_type_name(kind, original)
			mut c_name := without_prefix(original, 'C.')
			if c_name == 'Stbrp_node' {
				c_name = 'stbrp_node'
			}
			if c_name == 'Stbrp_context_opaque' {
				c_name = 'stbrp_context_opaque'
			}
			if kind == 'implot' && imported_structs[c_name] {
				if c_name in imported_aliases && !seen_type[clean] {
					seen_type[clean] = true
					out << 'pub type ${clean} = imgui.${imported_aliases[c_name]}'
				}
				index++
				continue
			}
			if clean !in ['Main', 'C'] && !clean.contains('.') && !seen_struct[clean] {
				seen_struct[clean] = true
				block := emit_struct(kind, original, clean, body)
				if block != '' { out << block }
			}
			index++
			continue
		}
		if raw_name, raw_rhs := type_alias(line) {
			name := clean_type_name(kind, raw_name)
			mut rhs := clean_type_expr(kind, raw_rhs)
			if kind == 'implot' && raw_rhs.trim_space().starts_with('C.') {
				c_name := raw_rhs.trim_space()[2..]
				if imported_structs[c_name] && c_name in imported_aliases {
					rhs = 'imgui.' + imported_aliases[c_name]
				}
			}
			rhs = normalize_alias_rhs(kind, name, rhs)
			if name != '' && !name.contains('.') && name != 'Main' && name != rhs && !seen_type[name] {
				seen_type[name] = true
				out << 'pub type ${name} = ${rhs}'
			}
			index++
			continue
		}
		cleaned := clean_line(kind, line)
		if cleaned.trim_space() != '' || (out.len > 0 && out.last().trim_space() != '') {
			out << cleaned
		}
		index++
	}
	mut body := postprocess(kind, out.join('\n') + '\n')
	dynamic := dynamic_missing_decls(ctx, body, imported_structs, imported_aliases, imported_types)
	mut final := postprocess(kind, header_text(ctx, version, number) + dynamic + body)
	final = final_sanitize(kind, final)
	final = insert_after_version(final, header_alias_decls(ctx, final))
	final = insert_after_version(final, missing_c_alias_target_decls(final, imported_structs))
	final = final_sanitize(kind, final)
	os.write_file(output_path, final)!
	println('cleaned ${kind}: ${input_path} -> ${output_path}')
}

fn self_test() {
	assert split_top_level_commas('a int, callback fn (i32, i32), values [2]f32') == [
		'a int',
		' callback fn (i32, i32)',
		' values [2]f32',
	]
	assert camel_to_snake('ImGuiWindowFlags') == 'im_gui_window_flags'
	assert snake_to_camel('set_next_window_pos') == 'SetNextWindowPos'
	assert clean_type_expr('imgui', '&ImGuiContext') == '&Context'
	assert clean_type_expr('implot', 'C.ImPlotSpec_c') == 'C.Spec_c'
	assert clean_type_expr('implot', '&ImGuiContext') == '&imgui.Context'
	assert postprocess_identifiers('value int, callback C.int(x), args va_list, c C.va_list') == 'value i32, callback (x), args Va_list, c C.va_list'
	known := {
		'first': i64(1 << 4)
	}
	assert eval_enum_value('first | 1 << 2', known) or { i64(-1) } == 20
	println('cleanup_imgui_implot.vsh self-test passed')
}

fn main() {
	if os.args.len == 2 && os.args[1] == '--self-test' {
		self_test()
		return
	}
	if os.args.len != 4 {
		usage()
		exit(2)
	}
	clean_one(os.args[3], os.args[1], os.args[2]) or {
		eprintln(err)
		exit(1)
	}
}
