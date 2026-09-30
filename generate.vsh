#!/usr/bin/env -S v run

// Canonical ImGui/ImPlot binding generator.

import os

const repo_dir = @DIR
const c2v_flags = '-DSTATIC_BUILD=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=ON -DIMGUI_STATIC=OFF -DCIMGUI_NO_EXPORT=ON -DCIMGUI_USE_GLFW=ON'

fn usage() {
	println('Usage: v run generate.vsh [--regenerate-c|--self-test]')
	println('By default, translate the generated C API committed by cimgui/cimplot.')
}

fn run_at(command string, directory string) ! {
	println('\n> ${command}')
	result := os.execute('cd ${os.quoted_path(directory)} && ${command}')
	if result.output.trim_space() != '' {
		println(result.output.trim_right('\r\n'))
	}
	if result.exit_code != 0 {
		return error('command failed with exit code ${result.exit_code}')
	}
}

fn translate_header(header string, directory string) ! {
	c2v_bin := os.getenv('C2V_BIN')
	if c2v_bin != '' {
		run_at('${os.quoted_path(c2v_bin)} ${os.quoted_path(header)}', directory)!
	} else {
		run_at('v translate ${os.quoted_path(header)}', directory)!
	}
}

fn remove_file(path string) ! {
	if os.is_file(path) {
		os.rm(path)!
	}
}

fn copy_sources(source_dir string, suffix string, destination string) ! {
	os.mkdir_all(destination)!
	mut names := os.ls(source_dir)!
	names.sort()
	mut copied := 0
	for name in names {
		source := os.join_path(source_dir, name)
		if !name.ends_with(suffix) || !os.is_file(source) {
			continue
		}
		target := os.join_path(destination, name)
		os.cp(source, target) or { return error('copy ${source} -> ${target}: ${err}') }
		copied++
	}
	if copied == 0 {
		return error('no ${suffix} files in ${source_dir}')
	}
}

fn copy_sources_self_test() ! {
	root := os.join_path(os.temp_dir(), 'imgui-generator-copy-${os.getpid()}')
	source_dir := os.join_path(root, 'imgui', 'imgui', 'source')
	destination := os.join_path(root, 'imgui', 'imgui', 'include')
	os.mkdir_all(source_dir)!
	defer {
		os.rmdir_all(root) or {}
	}
	os.write_file(os.join_path(source_dir, 'api.h'), 'header')!
	os.write_file(os.join_path(source_dir, 'backend.cpp'), 'source')!
	os.write_file(os.join_path(source_dir, 'ignored.txt'), 'ignore')!
	os.mkdir_all(os.join_path(source_dir, 'nested.h'))!
	copy_sources(source_dir, '.h', destination)!
	copy_sources(source_dir, '.cpp', destination)!
	assert os.read_file(os.join_path(destination, 'api.h'))! == 'header'
	assert os.read_file(os.join_path(destination, 'backend.cpp'))! == 'source'
	assert !os.exists(os.join_path(destination, 'ignored.txt'))
	assert !os.exists(os.join_path(destination, 'nested.h'))
	println('Generator source-copy self-test passed.')
}

fn add_translation_fix(path string) ! {
	lines := os.read_lines(path)!
	mut output := []string{cap: lines.len + 16}
	mut previous_nonempty := ''
	for line in lines {
		trimmed := line.trim_space()
		is_plain_typedef := trimmed.starts_with('typedef ')
			&& !trimmed.starts_with('typedef struct ') && !trimmed.starts_with('typedef enum ')
		closed_struct := previous_nonempty in ['};', '}']
		if is_plain_typedef && closed_struct
			&& (output.len == 0 || output.last().trim_space() != 'struct ____TRANSLATIONFIX____;') {
			output << ''
			output << ''
			output << 'struct ____TRANSLATIONFIX____;'
		}
		output << line
		if trimmed != '' {
			previous_nonempty = trimmed
		}
	}
	os.write_file(path, output.join('\n') + '\n')!
}

fn main() {
	mut regenerate_c := false
	for arg in os.args[1..] {
		match arg {
			'--regenerate-c' {
				regenerate_c = true
			}
			'--self-test' {
				copy_sources_self_test() or { panic(err) }
				return
			}
			'-h', '--help' {
				usage()
				return
			}
			else {
				eprintln('Unknown option: ${arg}')
				usage()
				exit(2)
			}
		}
	}

	println('Generating bindings in ${repo_dir}')
	remove_file(os.join_path(repo_dir, 'cimgui', 'CMakeCache.txt')) or { panic(err) }
	remove_file(os.join_path(repo_dir, 'cimplot', 'CMakeCache.txt')) or { panic(err) }
	remove_file(os.join_path(repo_dir, 'CMakeCache.txt')) or { panic(err) }

	if regenerate_c {
		run_at('luajit ./generator.lua gcc internal glfw', os.join_path(repo_dir, 'cimgui', 'generator')) or { panic(err) }
	} else {
		println('Using the generated cimgui API committed by the pinned revision.')
	}
	include_dir := os.join_path(repo_dir, 'include')
	copy_sources(os.join_path(repo_dir, 'cimgui'), '.h', include_dir) or { panic(err) }
	copy_sources(os.join_path(repo_dir, 'cimgui'), '.cpp', include_dir) or { panic(err) }
	add_translation_fix(os.join_path(include_dir, 'cimgui.h')) or { panic(err) }

	if regenerate_c {
		run_at('luajit ./generator.lua gcc internal glfw', os.join_path(repo_dir, 'cimplot', 'generator')) or { panic(err) }
	} else {
		println('Using the generated cimplot API committed by the pinned revision.')
	}
	copy_sources(os.join_path(repo_dir, 'cimplot'), '.h', include_dir) or { panic(err) }
	copy_sources(os.join_path(repo_dir, 'cimplot'), '.cpp', include_dir) or { panic(err) }
	add_translation_fix(os.join_path(include_dir, 'cimplot.h')) or { panic(err) }

	imgui_include := os.join_path(include_dir, 'imgui') + os.path_separator
	implot_include := os.join_path(include_dir, 'implot') + os.path_separator
	os.mkdir_all(imgui_include)!
	os.mkdir_all(implot_include)!
	run_at('git checkout-index -a -f --prefix=${os.quoted_path(imgui_include)}', os.join_path(repo_dir, 'cimgui', 'imgui')) or { panic(err) }
	run_at('git checkout-index -a -f --prefix=${os.quoted_path(implot_include)}', os.join_path(repo_dir, 'cimplot', 'implot')) or { panic(err) }

	os.write_file(os.join_path(include_dir, 'c2v.toml'), '[project]\nadditional_flags = "${c2v_flags}"\n')!
	translate_header('cimgui.h', include_dir) or { panic(err) }
	translate_header('cimplot.h', include_dir) or { panic(err) }
	remove_file(os.join_path(include_dir, 'cimgui.json')) or { panic(err) }
	remove_file(os.join_path(include_dir, 'cimplot.json')) or { panic(err) }

	imgui_binding := os.join_path(repo_dir, 'imgui.v')
	implot_binding := os.join_path(repo_dir, 'implot', 'implot.v')
	os.mv(os.join_path(include_dir, 'cimgui.v'), imgui_binding)!
	os.mv(os.join_path(include_dir, 'cimplot.v'), implot_binding)!
	cleanup := os.join_path(repo_dir, 'cleanup_imgui_implot.vsh')
	run_at('v run ${os.quoted_path(cleanup)} ${os.quoted_path(imgui_binding)} ${os.quoted_path(imgui_binding)} imgui', repo_dir) or { panic(err) }
	run_at('v run ${os.quoted_path(cleanup)} ${os.quoted_path(implot_binding)} ${os.quoted_path(implot_binding)} implot', repo_dir) or { panic(err) }
	run_at('v fmt -w ${os.quoted_path(imgui_binding)}', repo_dir) or { panic(err) }
	// vfmt restores a space before fixed-array types. V3 currently treats that
	// form as an embedded-struct attribute when the C field name is uppercase.
	run_at('v run ${os.quoted_path(cleanup)} --v3-fixed-arrays ${os.quoted_path(imgui_binding)}', repo_dir) or {
		panic(err)
	}
	// Do not format ImPlot: its C field/type pair `Marker Marker` is currently
	// collapsed by vfmt into invalid V.
	run_at('v run ${os.quoted_path(os.join_path(repo_dir, 'build_vimgui.vsh'))}', repo_dir) or {
		panic(err)
	}
}
