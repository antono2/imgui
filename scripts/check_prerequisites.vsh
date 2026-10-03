#!/usr/bin/env -S v run

import os
import tooling

fn main() {
	args := os.args[1..]
	if args == ['--help'] || args == ['-h'] {
		println('Usage: ./scripts/check_prerequisites.vsh [--glfw system|bundled]')
		return
	}
	mut bundled := false
	$if windows {
		bundled = true
	}
	if args.len > 0 {
		if args.len != 2 || args[0] != '--glfw' || args[1] !in ['system', 'bundled'] {
			eprintln('Usage: ./scripts/check_prerequisites.vsh [--glfw system|bundled]')
			exit(2)
		}
		bundled = args[1] == 'bundled'
	}
	if !bundled {
		tooling.system_glfw() or {
			eprintln(err)
			exit(1)
		}
	}
	tooling.check_prerequisites(bundled) or {
		eprintln(err)
		exit(1)
	}
}
