// Once Git, the Vulkan SDK, MSVC and V are ready, build the pinned Windows demo.
import os
import rand
import strconv
import tooling

const usage = 'Usage: v run scripts/setup_windows_demo.vsh [--run]'
// Keep the scratch component short for the Windows C compiler and linker.
const scratch_id_length = 8

fn allow_git_long_paths() ! {
	configured := os.getenv('GIT_CONFIG_COUNT')
	count := if configured == '' {
		0
	} else {
		strconv.atoi(configured) or { return error('GIT_CONFIG_COUNT must be a nonnegative integer.') }
	}
	if count < 0 || count == max_int {
		return error('GIT_CONFIG_COUNT must be a nonnegative integer.')
	}
	os.setenv('GIT_CONFIG_KEY_${count}', 'core.longpaths', true)
	os.setenv('GIT_CONFIG_VALUE_${count}', 'true', true)
	os.setenv('GIT_CONFIG_COUNT', (count + 1).str(), true)
}

fn run(args []string) ! {
	if args in [['-h'], ['--help']] {
		println(usage)
		return
	}
	if args.len > 0 && args != ['--run'] {
		return error(usage)
	}
	if os.user_os() != 'windows' {
		return error('Windows demo setup requires Windows and the MSVC x64 toolchain.')
	}
	allow_git_long_paths()!
	root := os.dir(@DIR)
	build := os.join_path(root, 'build')
	modules := os.join_path(build, 'windows-modules')
	scratch_parent := os.join_path(build, '.vtmp')
	os.mkdir_all(scratch_parent)!
	scratch := os.join_path(scratch_parent, rand.uuid_v4()[..scratch_id_length])
	os.mkdir(scratch)!
	defer {
		os.rmdir_all(scratch) or { eprintln('Could not remove the build scratch directory: ${err}') }
	}
	// Keep generated files on the checkout drive and leave the user's VPM cache alone.
	os.setenv('VMODULES', modules, true)
	os.setenv('VTMP', scratch, true)
	os.chdir(root)!
	tooling.prepare_pinned_modules(root, modules)!
	compiler := tooling.compiler()
	tooling.command(compiler, ['-cc', 'msvc', 'run', 'scripts/check_installed_deps.vsh'])!
	tooling.command(compiler, ['-old-compiler', '-check-syntax', 'imgui.v'])!
	mut options := ['-cc', 'msvc', 'run', 'scripts/run_demo.vsh']
	if args.len == 0 {
		options << '--build-only'
	}
	tooling.command(compiler, options)!
}

run(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
