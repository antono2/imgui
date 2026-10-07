#!/usr/bin/env -S v run
// Prepares and launches the desktop demo with the chosen native-library configuration.

import os
import tooling

fn usage() {
	println('Usage: ./scripts/run_demo.vsh [--build-only|--native-only] [--demo-directory PATH] [--demo-source PATH] [--demo-revision COMMIT]\n\nBuild the native library and launch the pinned GLFW/Vulkan demo.\nA supplied checkout is used as-is. Compiling the bindings can need about 11 GiB.\nOn Windows: v run scripts/run_demo.vsh [options]')
}

fn run() ! {
	args := os.args[1..]
	mut build_only := false
	mut native_only := false
	mut demo_directory := ''
	mut demo_source := ''
	mut revision := '573e3935361aa7390769033ba52a1921630f1c03'
	mut index := 0
	for index < args.len {
		match args[index] {
			'--help', '-h' {
				usage()
				return
			}
			'--build-only' {
				build_only = true
			}
			'--native-only' {
				native_only = true
			}
			'--demo-directory', '--demo-source', '--demo-revision' {
				if index + 1 >= args.len {
					return error('${args[index]} requires a value')
				}
				match args[index] {
					'--demo-directory' {
						demo_directory = os.real_path(args[index + 1])
					}
					'--demo-source' {
						demo_source = os.real_path(args[index + 1])
					}
					else {
						revision = args[index + 1]
					}
				}
				index++
			}
			else {
				return error('Unknown option: ${args[index]}')
			}
		}
		index++
	}
	root := os.dir(os.dir(os.real_path(@FILE)))
	mut bundled := false
	$if windows {
		bundled = true
	}
	if !bundled { tooling.system_glfw()! }
	tooling.check_prerequisites(bundled)!
	if os.exists(os.join_path(root, '.git')) {
		tooling.command('git', ['-C', root, 'submodule', 'update', '--init', '--recursive'])!
	}
	mut native_options := ['run', os.join_path(root, 'build_vimgui.vsh'), '--linkage', 'shared',
		'--glfw', if bundled { 'bundled' } else { 'system' }]
	if bundled { native_options << ['--glfw-version', '3.4'] }
	tooling.command(tooling.compiler(), native_options)!
	if native_only {
		println('Built and checked native libraries.')
		return
	}
	tooling.install_modules(root)!
	if demo_directory == '' {
		demo_directory = os.join_path(root, 'build', 'v_imgui_examples')
		if !os.exists(os.join_path(demo_directory, '.git')) {
			tooling.command('git', ['clone', 'https://github.com/antono2/v_imgui_examples.git',
				demo_directory])!
		}
		if tooling.output('git', ['-C', demo_directory, 'status', '--porcelain'])! != '' {
			return error('The cached demo has local changes; preserve them or pass --demo-directory to use the checkout as-is.')
		}
		tooling.command('git', ['-C', demo_directory, 'fetch', '--quiet', 'origin', revision])!
		tooling.command('git', ['-C', demo_directory, 'checkout', '--quiet', '--detach', revision])!
	}
	if demo_source == '' {
		demo_source = demo_directory
	}
	if !os.exists(demo_source) {
		return error('Demo source does not exist: ${demo_source}')
	}
	mut runtime := os.join_path(root, 'build', 'desktop-demo')
	mut extension := ''
	mut cc := 'gcc'
	$if macos {
		cc = 'clang'
	}
	$if windows {
		cc = 'msvc'
		extension = '.exe'
		runtime = os.join_path(root, 'build', 'windows-demo')
		native_dir := os.join_path(root, 'build', 'shared-bundled-3.4')
		header := tooling.find_file(native_dir, ['glfw3.h'], 'glfw-src')!
		library := tooling.find_file(native_dir, ['glfw3dll.lib', 'glfw3.lib'], '')!
		links := os.join_path(runtime, 'link')
		tooling.copy(library, os.join_path(links, 'glfw3.lib'))!
		os.setenv('GLFW_INCLUDE', os.dir(os.dir(header)), true)
		os.setenv('GLFW_LIB', links, true)
		_ = tooling.find_file(os.join_path(root, 'lib'), ['vimgui.lib'], '')!
		tooling.copy(tooling.find_file(os.join_path(root, 'lib'), ['vimgui.dll'], '')!, os.join_path(runtime, 'vimgui.dll'))!
		tooling.copy(tooling.find_file(native_dir, ['glfw3.dll'], '')!, os.join_path(runtime, 'glfw3.dll'))!
	}
	os.mkdir_all(runtime)!
	demo_binary := os.join_path(runtime, 'v_imgui_demo' + extension)
	module_path := tooling.demo_module_path(root, runtime)!
	tooling.command(tooling.compiler(), ['-old-compiler', '-path', module_path, '-cc', cc, '-o',
		demo_binary, demo_source])!
	println('Built ${demo_binary}')
	if !build_only { tooling.command(demo_binary, [])! }
}

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}
