module tooling

import os
import v.vmod

// Use the compiler executable, not a shell wrapper that can reinterpret -path.
pub fn compiler() string {
	return if os.getenv('V_BIN') == '' { @VEXE } else { os.getenv('V_BIN') }
}

fn executable(program string) !string {
	if os.is_file(program) {
		return os.real_path(program)
	}
	return os.find_abs_path_of_executable(program)
}

// Argument vectors preserve spaces, Unicode, and literal V module separators.
pub fn command(program string, args []string) ! {
	mut process := os.new_process(executable(program)!)
	process.set_args(args)
	process.run()
	process.wait()
	code := process.code
	process.close()
	if code != 0 {
		return error('${program} failed with exit code ${code}')
	}
}

pub fn output(program string, args []string) !string {
	mut process := os.new_process(executable(program)!)
	process.set_args(args)
	process.set_redirect_stdio_merged()
	process.run()
	text := process.stdout_slurp()
	process.wait()
	code := process.code
	process.close()
	if code != 0 {
		return error('${program} failed with exit code ${code}: ${text.trim_space()}')
	}
	return text.trim_space()
}

pub fn install_modules(root string) ! {
	manifest := vmod.from_file(os.join_path(root, 'v.mod'))!
	for dependency in manifest.dependencies {
		name := dependency.split('@')[0].all_after_last('.')
		if os.is_file(os.join_path(os.dir(root), name, 'v.mod')) {
			println('Using checked-out ${dependency.split('@')[0]} module.')
			continue
		}
		command(compiler(), ['install', dependency])!
	}
}

pub fn copy(source string, destination string) ! {
	os.mkdir_all(os.dir(destination))!
	os.cp(os.real_path(source), destination)!
}

pub fn find_file(root string, names []string, containing string) !string {
	mut files := os.walk_ext(root, '')
	files.sort()
	for file in files {
		if os.file_name(file) in names && file.contains(containing) {
			return file
		}
	}
	return error('Missing build output ${names} in ${root}')
}
