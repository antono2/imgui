#!/usr/bin/env -S v run
// Builds the application-widget host and its platform accessibility dependencies.

import os
import tooling

fn run() ! {
	if os.args[1..] == ['--help'] || os.args[1..] == ['-h'] {
		println('Usage: ./scripts/build_appui.vsh [CMAKE_CONFIGURE_OPTIONS...]\nOn Windows: v run scripts/build_appui.vsh [options]')
		return
	}
	root := os.dir(os.dir(os.real_path(@FILE)))
	build := os.join_path(root, 'build', 'appui')
	mut options := ['-S', os.join_path(root, 'native', 'application'), '-B', build,
		'-DCMAKE_BUILD_TYPE=Release']
	options << os.args[1..]
	tooling.command('cmake', options)!
	tooling.command('cmake', ['--build', build, '--config', 'Release', '--parallel', '2'])!
}

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}
