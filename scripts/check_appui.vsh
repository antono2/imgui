// Run the Linux application-host startup and software rendering regressions.
import arrays
import os
import tooling

const usage = 'Usage: v run scripts/check_appui.vsh startup SCRATCH_DIRECTORY | render'
const invalid_arguments_status = 2
const lavapipe_manifests = ['/usr/share/vulkan/icd.d/lvp_icd.x86_64.json',
	'/usr/share/vulkan/icd.d/lvp_icd.json']

fn check_startup(root string, scratch string) ! {
	directory := os.abs_path(scratch)
	os.mkdir_all(directory)!
	probe := os.join_path(directory, 'window-startup-probe')
	check := os.join_path(directory, 'window-startup-check')
	compiler := tooling.compiler()
	tooling.command(compiler, ['-cc', 'tcc', '-o', probe,
		os.join_path(root, 'tests', 'desktop', 'startup_probe.v')])!
	tooling.command(compiler, ['-cc', 'tcc', '-o', check,
		os.join_path(root, 'tests', 'desktop', 'window_startup.v')])!
	tooling.command(check, [probe, os.join_path(directory, 'window-startup-logs')])!
}

fn render(root string) ! {
	icd := arrays.find_first(lavapipe_manifests, os.is_file) or {
		return error('Install Mesa Lavapipe to run the application-host rendering regression.')
	}
	os.setenv('VK_DRIVER_FILES', icd, true)
	os.setenv('VK_ICD_FILENAMES', icd, true)
	os.setenv('G_DEBUG', 'fatal-criticals', true)
	os.setenv('GSETTINGS_BACKEND', 'memory', true)
	host := os.join_path(root, 'build', 'appui', 'application_host_smoke')
	if !os.is_executable(host) {
		return error('Run v run scripts/build_appui.vsh to build the application host before rendering.')
	}
	tooling.command('dbus-run-session', ['--', 'xvfb-run', '-a', host])!
}

fn run(args []string) ! {
	root := os.dir(@DIR)
	if args == ['--help'] || args == ['-h'] {
		println(usage)
		return
	}
	if args.len == 2 && args[0] == 'startup' && args[1] != '' {
		check_startup(root, args[1])!
	} else if args == ['render'] {
		render(root)!
	} else {
		return error_with_code(usage, invalid_arguments_status)
	}
}

fn main() {
	run(os.args[1..]) or {
		eprintln(err)
		exit(if err.code() > 0 { err.code() } else { 1 })
	}
}
