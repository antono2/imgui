// Reproduce the compatibility, frontend and consumer checks for prebuilt demos.
import os
import tooling

const usage = 'Usage: v run scripts/check_demo_release.vsh compatibility | variant | frontend DEMO_DIRECTORY | moving-consumer SCRATCH'
const usage_status = 2

fn compatibility(root string) ! {
	output := os.getenv('GITHUB_OUTPUT')
	if output == '' {
		return error('Set GITHUB_OUTPUT to the compatibility output file.')
	}
	script := os.join_path(root, 'scripts', 'compatibility.vsh')
	tooling.command(tooling.compiler(), ['run', script, '--self-test'])!
	tooling.command(tooling.compiler(), ['run', os.join_path(root, 'scripts', 'doctor.vsh'),
		'--self-test'])!
	tooling.command(tooling.compiler(), ['run', script, '--github-output', output])!
}

fn variant_checks(root string) ! {
	os.chdir(root)!
	for args in [
		['run', 'setup.vsh', '--check'],
		['run', 'generate.vsh', '--help'],
		['run', 'generate.vsh', '--self-test'],
		['run', 'scripts/check_upstream_variant.vsh'],
		['run', 'cleanup_imgui_implot.vsh', '--self-test'],
		['run', 'scripts/configure_variant.vsh', '--self-test'],
		['run', 'build_vimgui.vsh', '--help'],
	] {
		tooling.command(tooling.compiler(), args)!
	}
}

fn module_path() !string {
	modules := os.getenv('VMODULES')
	if modules == '' {
		return error('Set VMODULES to the isolated checkout used for the demo.')
	}
	return '${os.join_path(os.abs_path(modules), 'antono2')}|@vlib|@vmodules'
}

fn frontend(root string, demo string) ! {
	compiler := tooling.compiler()
	for file in ['imgui.v', 'implot/implot.v'] {
		tooling.command(compiler, ['-new-compiler', '-check-syntax', os.join_path(root, file)])!
	}
	tooling.command(compiler, ['-new-compiler', '-check', '-path', module_path()!, demo])!
}

fn build_moving_consumer(root string, scratch string) ! {
	compiler := tooling.compiler()
	path := module_path()!
	previous := os.getwd()
	os.chdir(root)!
	tooling.command(compiler, ['run', 'build_vimgui.vsh', '--linkage', 'shared', '--glfw', 'system'])!
	os.chdir(previous)!
	binary := os.join_path(scratch, 'v_imgui_moving_deps')
	// This advisory check uses current V, where V3 is the default frontend.
	tooling.command(compiler, ['-no-memory-limit', '-path', path, '-cc', 'gcc',
		'-o', binary, os.join_path(root, 'tests', 'desktop', 'moving_dependencies_smoke.v')])!
	tooling.command(binary, [])!
}

fn run(args []string) ! {
	if args in [['--help'], ['-h']] {
		println(usage)
		return
	}
	root := os.dir(@DIR)
	match true {
		args == ['compatibility'] { compatibility(root)! }
		args == ['variant'] { variant_checks(root)! }
		args.len == 2 && args[0] == 'frontend' && args[1] != '' {
			frontend(root, os.abs_path(args[1]))!
		}
		args.len == 2 && args[0] == 'moving-consumer' && args[1] != '' {
			build_moving_consumer(root, os.abs_path(args[1]))!
		}
		else { return error_with_code(usage, usage_status) }
	}
}

run(os.args[1..]) or {
	eprintln(err)
	exit(if err.code() > 0 { err.code() } else { 1 })
}
