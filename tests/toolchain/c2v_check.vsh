// Compare representative C2V fixtures using the compiler that builds the translator.
import os
import rand
import v.pref
import v.scanner
import v.token

// Vfmt preserves single-line blocks, so compare syntax tokens across layout changes.
fn syntax(source string) ![]string {
	mut lexer := scanner.new_scanner(&pref.Preferences{}, .normal)
	lexer.init(&token.File{ name: 'c2v fixture', size: source.len }, source)
	mut result := []string{}
	for {
		kind := lexer.scan()
		if kind == .eof { break }
		if kind == .semicolon { continue }
		value := if kind in [.name, .string, .number, .char, .hash] { lexer.lit } else { '' }
		result << '${kind}:${value}'
	}
	if lexer.diagnostics.len != 0 { return error('Invalid V syntax in C2V fixture') }
	return result
}

fn checked(args []string) ! {
	result := os.exec(args)
	if result.exit_code != 0 { return error('${args.join(' ')}\n${result.output}') }
}

fn run(args []string) ! {
	if args.len != 1 { return error('Usage: v run tests/toolchain/c2v_check.vsh C2V_CHECKOUT') }
	checkout := os.abs_path(args[0])
	binary := os.join_path(checkout, $if windows { 'c2v.exe' } $else { 'c2v' })
	if !os.is_executable(binary) {
		return error('Build the C2V translator with the tested V compiler first.')
	}
	temporary := os.join_path(os.temp_dir(), 'c2v qualifier ' + rand.uuid_v4())
	fixtures := os.join_path(temporary, 'tests')
	os.mkdir_all(fixtures)!
	defer { os.rmdir_all(temporary) or {} }
	for name in ['ptr_deref.c', '24.typedef_struct.h', '37.single_arg_fn_typedef.c',
		'50.cpp_nullptr_bool.cpp', '135.cpp_external_pointer_typedef_prototypes.cpp'] {
		input := os.join_path(fixtures, name)
		os.cp(os.join_path(checkout, 'tests', name), input)!
		extension := os.file_ext(input)
		stem := input.trim_string_right(extension)
		expected := os.join_path(fixtures, 'expected_' + name.all_before_last('.') + '.v')
		os.cp(os.join_path(checkout, 'tests', name.trim_string_right(extension) + '.out'), expected)!
		checked([if extension == '.cpp' { 'c++' } else { 'cc' }, '-c', '-w', input, '-o', stem + '.o'])!
		mut command := [binary]
		if extension == '.h' { command << 'wrapper' }
		command << input
		checked(command)!
		actual := stem + '.v'
		checked([@VEXE, 'fmt', '-w', actual, expected])!
		wanted := os.read_file(expected)!.trim_space()
		got := os.read_file(actual)!.after('// vstart').trim_space()
		if syntax(got)! != syntax(wanted)! { return error('C2V fixture syntax differs: ${name}') }
		println('PASS: ${name}')
	}
}

run(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
