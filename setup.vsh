#!/usr/bin/env -S v run

import os
import scripts.tooling

fn run() ! {
	args := os.args[1..]
	if args == ['--help'] || args == ['-h'] {
		println('Usage: ./setup.vsh [--install|--check]\n\nDefault: install dependencies and build the native ImGui library.\n--check: report prerequisites without changing the system or build tree.\nOn Windows: v run setup.vsh [options]')
		return
	}
	if args.len > 1 || (args.len == 1 && args[0] !in ['--install', '--check']) {
		return error('Usage: ./setup.vsh [--install|--check]')
	}
	install := args.len == 0 || args[0] == '--install'
	root := os.dir(os.real_path(@FILE))
	if install {
		tooling.install_system_dependencies()!
		tooling.install_modules(root)!
	}
	$if windows || macos {
		tooling.setup_vulkan(root, if install { '--install' } else { '--check' })!
	}
	mut bundled := false
	$if windows {
		bundled = true
	}
	if !bundled { tooling.system_glfw()! }
	tooling.check_prerequisites(bundled)!
	if install {
		if os.exists(os.join_path(root, '.git')) {
			tooling.command('git', ['-C', root, 'submodule', 'update', '--init', '--recursive'])!
		}
		mut options := ['run', os.join_path(root, 'build_vimgui.vsh'), '--linkage', 'shared', '--glfw',
			if bundled { 'bundled' } else { 'system' }]
		if bundled { options << ['--glfw-version', '3.4'] }
		tooling.command(tooling.compiler(), options)!
		println('\nNative libraries are ready. Launch the demo with ./scripts/run_demo.vsh (Windows: v run scripts/run_demo.vsh).')
	}
}

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}
