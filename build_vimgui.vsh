#!/usr/bin/env -S v

import os

const repo_dir = @DIR

fn usage() {
	println('Usage: v run build_vimgui.vsh [--linkage shared|static] [--glfw system|bundled] [--glfw-version VERSION]')
}

fn option_value(args []string, index int, option string) string {
	if index + 1 >= args.len {
		eprintln('${option} requires a value')
		exit(2)
	}
	return args[index + 1]
}

fn run(parts []string) {
	command := parts.map(os.quoted_path(it)).join(' ')
	println('> ${command}')
	result := os.execute_or_exit(command)
	if result.output != '' {
		print(result.output)
		if !result.output.ends_with('\n') {
			println('')
		}
	}
}

mut linkage := os.getenv('VIMGUI_LINKAGE')
if linkage == '' {
	linkage = 'shared'
}
mut glfw_provider := os.getenv('VIMGUI_GLFW_PROVIDER')
if glfw_provider == '' {
	glfw_provider = 'system'
}
mut glfw_version := os.getenv('VIMGUI_GLFW_VERSION')
if glfw_version == '' {
	glfw_version = '3.3'
}

args := os.args[1..]
mut index := 0
for index < args.len {
	match args[index] {
		'--linkage' {
			linkage = option_value(args, index, '--linkage')
			index += 2
		}
		'--glfw' {
			glfw_provider = option_value(args, index, '--glfw')
			index += 2
		}
		'--glfw-version' {
			glfw_version = option_value(args, index, '--glfw-version')
			index += 2
		}
		'-h', '--help' {
			usage()
			exit(0)
		}
		else {
			eprintln('Unknown option: ${args[index]}')
			usage()
			exit(2)
		}
	}
}

if linkage !in ['shared', 'static'] {
	eprintln('linkage must be shared or static')
	exit(2)
}
if glfw_provider !in ['system', 'bundled'] {
	eprintln('glfw provider must be system or bundled')
	exit(2)
}

if !os.is_file(os.join_path(repo_dir, 'CMakeLists.txt'))
	|| !os.is_file(os.join_path(repo_dir, 'cimgui', 'cimgui.cpp'))
	|| !os.is_file(os.join_path(repo_dir, 'cimplot', 'cimplot.cpp')) {
	eprintln('Missing cimgui or cimplot sources. Run generate_v.sh first (or initialise the submodules).')
	exit(1)
}

static_build := if linkage == 'static' { 'ON' } else { 'OFF' }
build_type := if os.getenv('CMAKE_BUILD_TYPE') == '' {
	'Release'
} else {
	os.getenv('CMAKE_BUILD_TYPE')
}
safe_glfw_version := glfw_version.replace('..', '_').replace('/', '_').replace('\\', '_')
build_dir := os.join_path(repo_dir, 'build', '${linkage}-${glfw_provider}-${safe_glfw_version}')
output_dir := os.join_path(repo_dir, 'lib')
os.mkdir_all(build_dir) or {
	eprintln('Could not create build directory ${build_dir}: ${err}')
	exit(1)
}

run([
	'cmake',
	'-S',
	repo_dir,
	'-B',
	build_dir,
	'-DVIMGUI_OUTPUT_DIR=${output_dir}',
	'-DSTATIC_BUILD=${static_build}',
	'-DVIMGUI_GLFW_PROVIDER=${glfw_provider}',
	'-DVIMGUI_GLFW_VERSION=${glfw_version}',
	'-DCMAKE_BUILD_TYPE=${build_type}',
	'-DCIMGUI_NO_EXPORT=ON',
])
run(['cmake', '--build', build_dir, '--parallel'])

println('Built vimgui in ${output_dir} (linkage: ${linkage}, GLFW: ${glfw_provider}, version: ${glfw_version})')
