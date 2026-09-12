#!/usr/bin/env -S v run

// Cross-platform entry point for the native Dear ImGui/ImPlot build.

import os

fn run(command string) ! {
	println('\n> ${command}')
	result := os.execute(command)
	if result.output.trim_space() != '' {
		println(result.output.trim_right('\r\n'))
	}
	if result.exit_code != 0 {
		return error('command failed with exit code ${result.exit_code}')
	}
}

fn setup_vulkan(mode string) ! {
	if mode == '--install' {
		run('v install antono2.vulkan')!
	}
	setup := os.join_path(os.vmodules_dir(), 'antono2', 'vulkan', 'setup.vsh')
	if !os.is_file(setup) {
		return error('antono2.vulkan does not include setup.vsh; install or update it first')
	}
	run('v run ${os.quoted_path(setup)} ${mode}')!
	$if windows {
		value := os.execute('powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable(\'VULKAN_SDK\', \'Machine\')"')
		if value.exit_code == 0 && value.output.trim_space() != '' {
			os.setenv('VULKAN_SDK', value.output.trim_space(), true)
		}
	}
}

fn main() {
	if os.args.len > 2 || (os.args.len == 2 && os.args[1] !in ['--install', '--check', '-h', '--help']) {
		eprintln('Usage: v run setup.vsh [--install|--check]')
		exit(2)
	}
	if os.args.len == 2 && os.args[1] in ['-h', '--help'] {
		println('Usage: v run setup.vsh [--install|--check]\n\nDefault: install dependencies and build the native ImGui library.\n--check: report prerequisites without changing the system or build tree.')
		return
	}
	install := os.args.len == 1 || os.args[1] == '--install'
	mode := if install { '--install' } else { '--check' }
	project_dir := os.dir(os.real_path(@FILE))
	$if linux {
		run('bash ${os.quoted_path(os.join_path(project_dir, 'scripts', 'setup_linux.sh'))} ${mode}') or {
			panic(err)
		}
		if install {
			run('git -C ${os.quoted_path(project_dir)} submodule update --init --recursive') or {
				panic(err)
			}
			run('v run ${os.quoted_path(os.join_path(project_dir, 'build_vimgui.vsh'))} --linkage shared --glfw system') or {
				panic(err)
			}
		}
	} $else $if macos {
		setup_vulkan(mode) or { panic(err) }
		if !os.exists_in_system_path('brew') {
			eprintln('Homebrew is required for automatic CMake and GLFW installation: https://brew.sh')
			exit(1)
		}
		if install {
			run('brew install cmake glfw') or { panic(err) }
			run('v install antono2.glfw') or { panic(err) }
			run('git -C ${os.quoted_path(project_dir)} submodule update --init --recursive') or {
				panic(err)
			}
			prefix := os.execute('brew --prefix glfw').output.trim_space()
			os.setenv('GLFW_INCLUDE', os.join_path(prefix, 'include'), true)
			os.setenv('GLFW_LIB', os.join_path(prefix, 'lib'), true)
			run('v run ${os.quoted_path(os.join_path(project_dir, 'build_vimgui.vsh'))} --linkage shared --glfw system') or {
				panic(err)
			}
		}
	} $else $if windows {
		setup_vulkan(mode) or { panic(err) }
		script := if install { 'run_demo_windows.ps1' } else { 'check_windows.ps1' }
		mut command := 'powershell -NoProfile -ExecutionPolicy Bypass -File ${os.quoted_path(os.join_path(project_dir, 'scripts', script))}'
		if install {
			command += ' -NativeOnly'
		} else {
			command += ' -BundledGlfw'
		}
		run(command) or { panic(err) }
	} $else {
		eprintln('Automatic setup is unsupported on this operating system.')
		exit(1)
	}
	if install {
		println('\nDear ImGui/ImPlot native libraries are ready. Run `./scripts/run_demo.sh` (Linux/macOS) or `scripts\\run_demo_windows.ps1` to launch the demo.')
	} else {
		println('\nDear ImGui/ImPlot prerequisite check passed.')
	}
}
