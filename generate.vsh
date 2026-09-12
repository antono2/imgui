#!/usr/bin/env -S v run

// Canonical ImGui/ImPlot binding generator.

import os

const repo_dir = @DIR
const c2v_flags = '-DSTATIC_BUILD=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=ON -DIMGUI_STATIC=OFF -DCIMGUI_NO_EXPORT=ON -DCIMGUI_USE_GLFW=ON'

fn usage() {
	println('Usage: v run generate.vsh [--regenerate-c]')
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

fn remove_file(path string) ! {
	if os.is_file(path) {
		os.rm(path)!
	}
}

fn copy_matching(pattern string, destination string) ! {
	files := os.glob(pattern) or { return error('could not expand ${pattern}: ${err}') }
	if files.len == 0 {
		return error('no files matched ${pattern}')
	}
	for source in files {
		os.cp(source, os.join_path(destination, os.file_name(source)))!
	}
}

fn add_translation_fix(path string) ! {
	program := r's/(struct\s[\w\d]+\s\{[^\}]+(?:union\s+\{[^\}]+\};[^\}]+)?\};\s)(typedef\s(?!struct|enum)[^\n]+)/$1\n\nstruct ____TRANSLATIONFIX____;\n$2/g'
	run_at('perl -p -i -g -e ${os.quoted_path(program)} ${os.quoted_path(path)}', repo_dir)!
}

fn main() {
	mut regenerate_c := false
	for arg in os.args[1..] {
		match arg {
			'--regenerate-c' {
				regenerate_c = true
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
	copy_matching(os.join_path(repo_dir, 'cimgui', '*.h'), include_dir) or { panic(err) }
	copy_matching(os.join_path(repo_dir, 'cimgui', '*.cpp'), include_dir) or { panic(err) }
	add_translation_fix(os.join_path(include_dir, 'cimgui.h')) or { panic(err) }

	if regenerate_c {
		run_at('luajit ./generator.lua gcc internal glfw', os.join_path(repo_dir, 'cimplot', 'generator')) or { panic(err) }
	} else {
		println('Using the generated cimplot API committed by the pinned revision.')
	}
	copy_matching(os.join_path(repo_dir, 'cimplot', '*.h'), include_dir) or { panic(err) }
	copy_matching(os.join_path(repo_dir, 'cimplot', '*.cpp'), include_dir) or { panic(err) }
	add_translation_fix(os.join_path(include_dir, 'cimplot.h')) or { panic(err) }

	imgui_include := os.join_path(include_dir, 'imgui') + os.path_separator
	implot_include := os.join_path(include_dir, 'implot') + os.path_separator
	os.mkdir_all(imgui_include)!
	os.mkdir_all(implot_include)!
	run_at('git checkout-index -a -f --prefix=${os.quoted_path(imgui_include)}', os.join_path(repo_dir, 'cimgui', 'imgui')) or { panic(err) }
	run_at('git checkout-index -a -f --prefix=${os.quoted_path(implot_include)}', os.join_path(repo_dir, 'cimplot', 'implot')) or { panic(err) }

	os.write_file(os.join_path(include_dir, 'c2v.toml'), '[project]\nadditional_flags = "${c2v_flags}"\n')!
	run_at('v translate cimgui.h', include_dir) or { panic(err) }
	run_at('v translate cimplot.h', include_dir) or { panic(err) }
	remove_file(os.join_path(include_dir, 'cimgui.json')) or { panic(err) }
	remove_file(os.join_path(include_dir, 'cimplot.json')) or { panic(err) }

	imgui_binding := os.join_path(repo_dir, 'imgui.v')
	implot_binding := os.join_path(repo_dir, 'implot', 'implot.v')
	os.mv(os.join_path(include_dir, 'cimgui.v'), imgui_binding)!
	os.mv(os.join_path(include_dir, 'cimplot.v'), implot_binding)!
	cleanup := os.join_path(repo_dir, 'cleanup_imgui_implot.perl')
	run_at('perl ${os.quoted_path(cleanup)} ${os.quoted_path(imgui_binding)} ${os.quoted_path(imgui_binding)} imgui', repo_dir) or { panic(err) }
	run_at('perl ${os.quoted_path(cleanup)} ${os.quoted_path(implot_binding)} ${os.quoted_path(implot_binding)} implot', repo_dir) or { panic(err) }
	run_at('v fmt -w ${os.quoted_path(imgui_binding)}', repo_dir) or { panic(err) }
	// Do not format ImPlot: its C field/type pair `Marker Marker` is currently
	// collapsed by vfmt into invalid V.
	run_at('v run ${os.quoted_path(os.join_path(repo_dir, 'build_vimgui.vsh'))}', repo_dir) or {
		panic(err)
	}
}
