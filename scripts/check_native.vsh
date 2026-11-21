// Build and check the Linux and mobile bindings with the same inputs as CI.
import os
import tooling

const usage = 'Usage: v run scripts/check_native.vsh COMMAND [ARGS...]
  compiler SOURCE [clang|master]
  compiler-path SOURCE
  linux-build BUILD_DIRECTORY
  linux-probes BUILD_DIRECTORY
  linux-callback BUILD_DIRECTORY SCRATCH
  android-api SCRATCH ABI
  apple-api SCRATCH SDK ARCH
  apple-build BUILD_DIRECTORY SDK ARCH
  apple-link BUILD_DIRECTORY SCRATCH SDK ARCH
  apple-verify BUILD_DIRECTORY SDK ARCH'

const usage_status = 2
const native_build_jobs = 4
const macos_deployment_target = '11.0'
const ios_deployment_target = '13.0'
const apple_library = 'libvimgui.dylib'
const apple_link_smoke_library = 'libvimgui_apple_link_smoke.dylib'
const ios_demo_name = 'vimgui_ios_demo'

struct AppleTarget {
	sdk      string
	arch     string
	v_arch   string
	platform string
	profile  string
	backend  string
}

fn build_compiler(source string, mode string) ! {
	// Make must write the source compiler locally. v run sets VEXE to the bootstrap.
	os.unsetenv('VEXE')
	mut args := ['-C', source]
	if mode != 'master' {
		args << 'local=1'
	}
	if mode == 'clang' {
		args << 'VFLAGS=-cc clang'
	}
	tooling.command('make', args)!
	register_compiler(source)!
}

fn register_compiler(source string) ! {
	name := $if windows { 'v.exe' } $else { 'v' }
	tooling.command(os.join_path(source, name), ['version'])!
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
	common := ['-path', module_path(root, scratch)!, '-os', target, '-arch', arch, '-shared', '-check']
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

fn apple_target(sdk string, arch string) !AppleTarget {
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
	return AppleTarget{sdk, arch, v_arch, platform, profile, backend}
}

fn apple_api(root string, scratch string, target AppleTarget) ! {
	check_api(root, scratch, target.platform, target.v_arch, target.profile,
		['impl_metal', target.backend, 'impl_mobile'])!
}

fn apple_build(root string, build string, target AppleTarget) ! {
	tooling.command('xcodebuild', ['-version'])!
	tooling.command('xcrun', ['--sdk', target.sdk, '--show-sdk-path'])!
	deployment := if target.platform == 'ios' {
		ios_deployment_target
	} else {
		macos_deployment_target
	}
	mut options := ['-S', root, '-B', build, '-G', 'Ninja', '-DCMAKE_OSX_SYSROOT=${target.sdk}',
		'-DCMAKE_OSX_ARCHITECTURES=${target.arch}', '-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment}',
		'-DVIMGUI_PROFILE=apple-metal', '-DIMGUI_FREETYPE=ON', '-DVIMGUI_FREETYPE_PROVIDER=bundled',
		'-DVIMGUI_BUILD_SMOKE_TESTS=ON', '-DSTATIC_BUILD=OFF', '-DCMAKE_BUILD_TYPE=Release']
	if target.platform == 'ios' {
		options << ['-DCMAKE_SYSTEM_NAME=iOS', '-DVIMGUI_BUILD_IOS_DEMO=ON']
	}
	tooling.command('cmake', options)!
	tooling.command('cmake', ['--build', build, '--parallel', native_build_jobs.str()])!
}

fn apple_arch(path string, arch string) ! {
	architectures := tooling.output('xcrun', ['lipo', '-archs', path])!
	if arch !in architectures.fields() {
		return error('Missing ${arch} in ${path}. Found architectures: ${architectures}')
	}
	println('Verified ${arch} in ${path}')
}

fn apple_link(root string, build string, scratch string, target AppleTarget) ! {
	path := module_path(root, scratch)!
	profile := os.join_path(root, 'lib', 'apple-metal', target.sdk, target.arch, 'freetype')
	tooling.copy(os.join_path(build, 'lib', apple_library), os.join_path(profile, apple_library))!
	sdk_path := tooling.output('xcrun', ['--sdk', target.sdk, '--show-sdk-path'])!
	clang := tooling.output('xcrun', ['--sdk', target.sdk, '--find', 'clang'])!
	mut flags := '-isysroot ${os.quoted_path(sdk_path)}'
	if target.platform == 'ios' {
		suffix := if target.sdk == 'iphonesimulator' { '-simulator' } else { '' }
		flags = '-target ${target.arch}-apple-ios${ios_deployment_target}${suffix} ${flags}'
	}
	probe := os.join_path(scratch, 'vimgui-v-apple-smoke')
	smoke := os.join_path(root, 'tests', 'apple', '${target.platform}_v_api_link_smoke.v')
	tooling.command(tooling.compiler(), ['-path', path, '-os', target.platform, '-arch', target.v_arch,
		'-cc', clang, '-cflags', flags, '-ldflags', flags, '-skip-running', '-d', target.profile,
		'-d', 'use_freetype', '-gc', 'none', '-no-memory-limit', '-o', probe, smoke])!
	apple_arch(probe, target.arch)!
}

fn apple_verify(build string, target AppleTarget) ! {
	library := os.join_path(build, 'lib', apple_library)
	mut artifacts := [library, os.join_path(build, apple_link_smoke_library)]
	mut exports := ['_vimgui_metal_init']
	demo := os.join_path(build, '${ios_demo_name}.app')
	demo_binary := os.join_path(demo, ios_demo_name)
	if target.platform == 'ios' {
		artifacts << [demo_binary, os.join_path(demo, 'Frameworks', apple_library)]
		exports << ['_vimgui_ios_keyboard_create', '_vimgui_ios_text_view_apply_edit']
	}
	for artifact in artifacts {
		if !os.is_file(artifact) {
			return error('Missing Apple build artifact: ${artifact}')
		}
	}
	apple_arch(library, target.arch)!
	symbols := tooling.output('xcrun', ['nm', '-gU', library])!.fields()
	for symbol in exports {
		if symbol !in symbols {
			return error('Missing export ${symbol} in ${library}')
		}
	}
	if target.platform == 'ios' {
		dependencies := tooling.output('xcrun', ['otool', '-L', library])!
		if !dependencies.contains('/GameController.framework/') {
			return error('Missing GameController linkage in ${library}')
		}
		apple_arch(demo_binary, target.arch)!
	}
	println('Verified exports in ${library}: ${exports.join(', ')}')
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
			build_compiler(os.abs_path(args[1]), '')!
		}
		args.len == 3 && args[0] == 'compiler' && args[2] in ['clang', 'master'] {
			build_compiler(os.abs_path(args[1]), args[2])!
		}
		args.len == 2 && args[0] == 'compiler-path' {
			register_compiler(os.abs_path(args[1]))!
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
			apple_api(root, os.abs_path(args[1]), apple_target(args[2], args[3])!)!
		}
		args.len == 4 && args[0] == 'apple-build' {
			apple_build(root, os.abs_path(args[1]), apple_target(args[2], args[3])!)!
		}
		args.len == 5 && args[0] == 'apple-link' {
			apple_link(root, os.abs_path(args[1]), os.abs_path(args[2]), apple_target(args[3],
				args[4])!)!
		}
		args.len == 4 && args[0] == 'apple-verify' {
			apple_verify(os.abs_path(args[1]), apple_target(args[2], args[3])!)!
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
