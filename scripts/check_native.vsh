// Build and check the Linux and mobile bindings with the same inputs as CI.
import os
import tooling

const usage = 'Usage: v run scripts/check_native.vsh COMMAND [ARGS...]
  compiler SOURCE [clang]
  linux-build BUILD_DIRECTORY
  linux-probes BUILD_DIRECTORY
  linux-callback BUILD_DIRECTORY SCRATCH
  android-api SCRATCH ABI
  apple-api SCRATCH SDK ARCH'

const usage_status = 2
const native_build_jobs = 4

fn build_compiler(source string, use_clang bool) ! {
	// Make must write the source compiler locally. v run sets VEXE to the bootstrap.
	os.unsetenv('VEXE')
	mut args := ['-C', source, 'local=1']
	if use_clang {
		args << 'VFLAGS=-cc clang'
	}
	tooling.command('make', args)!
	tooling.command(os.join_path(source, 'v'), ['version'])!
	output := os.getenv('GITHUB_PATH')
	if output != '' {
		if source.contains_any('\r\n') {
			return error('The compiler path cannot contain line breaks.')
		}
		mut file := os.open_append(output)!
		defer { file.close() }
		file.writeln(source)!
	}
}

fn linux_build(root string, build string) ! {
	tooling.command('cmake', ['-S', root, '-B', build, '-G', 'Ninja', '-DVIMGUI_PROFILE=desktop',
		'-DIMGUI_FREETYPE=ON', '-DVIMGUI_FREETYPE_PROVIDER=system', '-DVIMGUI_BUILD_SMOKE_TESTS=ON',
		'-DSTATIC_BUILD=OFF', '-DCMAKE_BUILD_TYPE=Release'])!
	tooling.command('cmake', ['--build', build, '--parallel', native_build_jobs.str()])!
}

fn linux_probes(build string) ! {
	tooling.use_lavapipe()!
	for test in ['vimgui_vulkan_offscreen_probe', 'vimgui_touch_tracker_test',
		'vimgui_text_offsets_test', 'vimgui_gamepad_values_test'] {
		tooling.command(os.join_path(build, test), [])!
	}
}

fn module_path(root string, scratch string) !string {
	modules := os.join_path(scratch, 'vmodules')
	package := os.join_path(modules, 'antono2', 'imgui')
	if os.exists(package) || os.is_link(package) {
		if os.real_path(package) != os.real_path(root) {
			return error('Module path points to another checkout: ${package}')
		}
	} else {
		os.mkdir_all(os.dir(package))!
		os.symlink(root, package)!
	}
	return '${modules}|@vlib|@vmodules'
}

fn linux_callback(root string, build string, scratch string) ! {
	path := module_path(root, scratch)!
	tooling.copy(os.join_path(build, 'lib', 'libvimgui.so'), os.join_path(root, 'lib', 'freetype',
		'libvimgui.so'))!
	probe := os.join_path(scratch, 'vimgui-input-text-callback')
	tooling.command(tooling.compiler(), ['-path', path, '-d', 'use_freetype', '-o', probe,
		os.join_path(root, 'tests', 'input_text_callback.v')])!
	tooling.command(probe, [])!
}

fn check_api(root string, scratch string, target string, arch string, profile string, modules []string) ! {
	compiler := tooling.compiler()
	common := ['-path', module_path(root, scratch)!, '-os', target, '-arch', arch, '-shared',
		'-check']
	mut root_args := common.clone()
	if profile != '' {
		root_args << ['-d', profile]
	}
	root_args << ['-d', 'use_freetype', root]
	tooling.command(compiler, root_args)!
	for name in modules {
		mut args := common.clone()
		args << os.join_path(root, name)
		tooling.command(compiler, args)!
	}
}

fn android_api(root string, scratch string, abi string) ! {
	arch := match abi {
		'armeabi-v7a' { 'arm' }
		'arm64-v8a' { 'arm64' }
		'x86_64' { 'amd64' }
		else { return error('Unsupported Android ABI: ${abi}') }
	}

	check_api(root, scratch, 'android', arch, '', ['impl_android', 'impl_mobile'])!
}

fn apple_api(root string, scratch string, sdk string, arch string) ! {
	v_arch := match arch {
		'x86_64' { 'amd64' }
		'arm64' { 'arm64' }
		else { return error('Unsupported Apple architecture: ${arch}') }
	}

	platform, profile, backend := match sdk {
		'macosx' { 'macos', 'imgui_metal', 'impl_osx' }
		'iphonesimulator' { 'ios', 'imgui_ios_simulator', 'impl_ios' }
		'iphoneos' { 'ios', 'imgui_ios_device', 'impl_ios' }
		else { return error('Unsupported Apple SDK: ${sdk}') }
	}

	check_api(root, scratch, platform, v_arch, profile, ['impl_metal', backend, 'impl_mobile'])!
}

fn run(args []string) ! {
	if args in [['--help'], ['-h']] {
		println(usage)
		return
	}
	if args.any(it == '') {
		return error_with_code(usage, usage_status)
	}
	root := os.dir(@DIR)
	match true {
		args.len == 2 && args[0] == 'compiler' {
			build_compiler(os.abs_path(args[1]), false)!
		}
		args.len == 3 && args[0] == 'compiler' && args[2] == 'clang' {
			build_compiler(os.abs_path(args[1]), true)!
		}
		args.len == 2 && args[0] == 'linux-build' {
			linux_build(root, os.abs_path(args[1]))!
		}
		args.len == 2 && args[0] == 'linux-probes' {
			linux_probes(os.abs_path(args[1]))!
		}
		args.len == 3 && args[0] == 'linux-callback' {
			linux_callback(root, os.abs_path(args[1]), os.abs_path(args[2]))!
		}
		args.len == 3 && args[0] == 'android-api' {
			android_api(root, os.abs_path(args[1]), args[2])!
		}
		args.len == 4 && args[0] == 'apple-api' {
			apple_api(root, os.abs_path(args[1]), args[2], args[3])!
		}
		else {
			return error_with_code(usage, usage_status)
		}
	}
}

fn main() {
	run(os.args[1..]) or {
		eprintln(err.msg())
		exit(if err.code() > 0 { err.code() } else { 1 })
	}
}
