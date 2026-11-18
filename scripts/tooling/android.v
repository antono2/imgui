// Build and package the Android NativeActivity examples with the installed SDK and NDK.
module tooling

import os
import rand
import strconv

const native_library = 'libvimgui.so'
const activity_library = 'libvimgui_android_demo.so'
const widget_library = 'libvimgui_android_ui.so'
const minimum_android_api = '24'
const java_bytecode = '8'
const zip_alignment = '4'

struct Abi {
	name         string
	v_arch       string
	clang_prefix string
}

const supported_abis = {
	'armeabi-v7a': Abi{'armeabi-v7a', 'arm', 'armv7a-linux-androideabi'}
	'arm64-v8a':   Abi{'arm64-v8a', 'arm64', 'aarch64-linux-android'}
	'x86_64':      Abi{'x86_64', 'amd64', 'x86_64-linux-android'}
}

struct AndroidTools {
	abi         Abi
	device      AndroidDevice
	toolchain   string
	build_tools string
	android_jar string
	clang       string
}

struct AndroidDevice {
	adb      string
	selector []string
}

fn android_setting(name string, default_value string) string {
	value := os.getenv(name)
	return if value == '' { default_value } else { value }
}

fn android_version(name string) ![]int {
	mut parts := []int{}
	for part in name.trim_string_left('android-').split('.') {
		if part == '' || !part.bytes().all(it.is_digit()) {
			return error('Not a numbered SDK version')
		}
		parts << strconv.atoi(part)!
	}
	return parts
}

fn newer_version(candidate []int, current []int) bool {
	count := if candidate.len > current.len { candidate.len } else { current.len }
	for index in 0 .. count {
		left := candidate[index] or { 0 }
		right := current[index] or { 0 }
		if left != right {
			return left > right
		}
	}
	return false
}

fn sdk_install(directory string, expected string) !string {
	mut version := []int{}
	mut best := ''
	mut names := os.ls(directory)!
	names.sort()
	for name in names {
		parts := android_version(name) or { continue }
		candidate := os.join_path(directory, name)
		if os.is_file(os.join_path(candidate, expected)) && (best == '' || newer_version(parts, version)) {
			best = candidate
			version = parts.clone()
		}
	}
	if best == '' {
		return error('No SDK installation with ${expected} under ${directory}')
	}
	return best
}

fn (device AndroidDevice) args(args []string) []string {
	mut invocation := device.selector.clone()
	invocation << args
	return invocation
}

fn android_device(sdk string) !AndroidDevice {
	mut adb := if sdk == '' { '' } else { os.join_path(sdk, 'platform-tools', 'adb') }
	if !os.is_executable(adb) {
		adb = os.find_abs_path_of_executable('adb')!
	}
	mut selector := []string{}
	serial := os.getenv('ANDROID_SERIAL')
	if serial != '' {
		selector << ['-s', serial]
	}
	return AndroidDevice{adb, selector}
}

fn (device AndroidDevice) abi() !string {
	reported := output(device.adb, device.args(['shell', 'getprop', 'ro.product.cpu.abi']))!
	// adb may announce a new server on stderr before returning the property.
	return reported.split_into_lines().filter(!it.starts_with('* daemon ')).join('\n').trim_space()
}

fn android_toolchain(ndk string) !string {
	toolchain := os.join_path(os.abs_path(ndk), 'build', 'cmake', 'android.toolchain.cmake')
	if ndk == '' || !os.is_file(toolchain) {
		return error('Set ANDROID_NDK_HOME to an installed NDK')
	}
	return toolchain
}

fn android_tools(deploy bool, compile_widgets bool) !AndroidTools {
	sdk_path := android_setting('ANDROID_SDK_ROOT', os.getenv('ANDROID_HOME'))
	ndk_path := android_setting('ANDROID_NDK_HOME', os.getenv('ANDROID_NDK_ROOT'))
	sdk := os.abs_path(sdk_path)
	ndk := os.abs_path(ndk_path)
	toolchain := android_toolchain(ndk_path)!
	if sdk_path == '' || !os.is_dir(os.join_path(sdk, 'build-tools')) {
		return error('Set ANDROID_SDK_ROOT to an installed Android SDK')
	}
	device := if deploy { android_device(sdk)! } else { AndroidDevice{} }
	mut abi_name := os.getenv('ANDROID_ABI')
	if abi_name == '' && deploy {
		abi_name = device.abi()!
	}
	abi := supported_abis[abi_name] or {
		return error('Set ANDROID_ABI to armeabi-v7a, arm64-v8a or x86_64')
	}
	build_tools := sdk_install(os.join_path(sdk, 'build-tools'), 'd8')!
	platform := sdk_install(os.join_path(sdk, 'platforms'), 'android.jar')!
	mut clang := ''
	if compile_widgets {
		prebuilt := os.join_path(ndk, 'toolchains', 'llvm', 'prebuilt')
		mut names := os.ls(prebuilt)!
		names.sort()
		for host in names {
			candidate := os.join_path(prebuilt, host, 'bin', abi.clang_prefix + minimum_android_api + '-clang')
			if os.is_executable(candidate) {
				clang = candidate
				break
			}
		}
		if clang == '' {
			return error('Cannot find the NDK Clang target for ${abi.name}')
		}
	}
	return AndroidTools{abi, device, toolchain, build_tools, os.join_path(platform, 'android.jar'), clang}
}

fn configure_android(root string, build string, tools AndroidTools, accessible bool, appui bool) ! {
	mut opts := ['-S', root, '-B', build, '-G', 'Ninja', '-DCMAKE_TOOLCHAIN_FILE=${tools.toolchain}',
		'-DANDROID_ABI=${tools.abi.name}', '-DANDROID_PLATFORM=android-${minimum_android_api}',
		'-DANDROID_STL=c++_static', '-DVIMGUI_PROFILE=android-vulkan', '-DSTATIC_BUILD=OFF',
		'-DCMAKE_BUILD_TYPE=Release', '-DVIMGUI_BUILD_ANDROID_DEMO=ON',
		'-DVIMGUI_APPLICATION_UI=' + if appui { 'ON' } else { 'OFF' },
		'-DVIMGUI_ANDROID_EXTERNAL_ACCESSIBILITY=' + if appui && !accessible { 'ON' } else { 'OFF' },
		'-DVIMGUI_ANDROID_ACCESSIBLE_DEMO=' + if accessible { 'ON' } else { 'OFF' }]
	if !accessible {
		opts << ['-DIMGUI_FREETYPE=ON', '-DVIMGUI_FREETYPE_PROVIDER=bundled']
	}
	command('cmake', opts)!
	parallel_jobs := if accessible { '2' } else { '4' }
	command('cmake', ['--build', build, '--target', 'vimgui_android_demo', '--parallel', parallel_jobs])!
}

fn build_widgets(root string, build string, ui string, tools AndroidTools, appui bool) ! {
	modules := os.join_path(build, 'vmodules')
	local := os.join_path(modules, 'antono2', 'imgui')
	os.mkdir_all(os.dir(local))!
	if os.is_link(local) {
		if os.real_path(local) != root {
			os.rm(local)!
			os.symlink(root, local)!
		}
	} else if !os.exists(local) {
		os.symlink(root, local)!
	} else if os.real_path(local) != root {
		return error('Expected a link to the ImGui checkout at ${local}')
	}
	library := os.join_path(root, 'lib', 'android-vulkan', tools.abi.name, 'freetype', native_library)
	copy(os.join_path(build, 'lib', native_library), library)!
	// The native host loads the widgets as a separate shared library.
	mut args := ['-path', '${modules}|@vlib|@vmodules', '-os', 'android', '-arch', tools.abi.v_arch,
		'-cc', tools.clang, '-d', 'use_freetype', '-gc', 'none', '-no-memory-limit', '-shared',
		'-o', os.join_path(build, widget_library), ui]
	if appui {
		args.prepend(['-d', 'appui_embedded', '-d', 'release_accessibility'])
	}
	command(compiler(), args)!
}

fn package_android(root string, build string, manifest string, tools AndroidTools, accessible bool) !string {
	stage := os.join_path(build, '.package-' + rand.uuid_v4())
	os.mkdir(stage, mode: 0o700)!
	defer { os.rmdir_all(stage) or {} }
	lib := 'lib/' + tools.abi.name
	assets := os.join_path(stage, 'assets')
	mut entries := [lib + '/' + native_library, lib + '/' + activity_library]
	copy(os.join_path(build, 'lib', native_library), os.join_path(stage, entries[0]))!
	copy(os.join_path(build, activity_library), os.join_path(stage, entries[1]))!
	if !accessible {
		entry := lib + '/' + widget_library
		copy(os.join_path(build, widget_library), os.join_path(stage, entry))!
		entries << entry
	}
	copy(os.join_path(root, 'cimgui', 'imgui', 'misc', 'fonts', 'Roboto-Medium.ttf'),
		os.join_path(assets, 'Roboto-Medium.ttf'))!
	source := os.join_path(root, 'android', 'java', 'io', 'antono2', 'imgui')
	compile_dex(stage, [
		os.join_path(source, 'ImGuiInputView.java'),
		os.join_path(source, 'ImGuiAccessibility.java'),
		os.join_path(root, 'examples', 'android_vulkan', 'java', 'io', 'antono2', 'vimgui', 'demo',
			'ImGuiActivity.java'),
	], tools)!
	entries << 'classes.dex'
	stem := if accessible { 'accessible' } else { 'vimgui-demo' }
	unsigned := os.join_path(build, stem + '-unsigned.apk')
	aligned := os.join_path(build, stem + '-aligned.apk')
	signed := os.join_path(build, stem + '-' + tools.abi.name + '.apk')
	aapt := os.join_path(tools.build_tools, 'aapt')
	command(aapt, ['package', '-f', '-M', manifest, '-I', tools.android_jar, '-A', assets, '-F',
		unsigned])!
	add_apk_entries(aapt, stage, unsigned, entries)!
	sign_apk(tools, os.join_path(build, 'debug.keystore'), unsigned, aligned, signed)!
	return signed
}

fn compile_dex(stage string, sources []string, tools AndroidTools) ! {
	classes := os.join_path(stage, 'classes')
	dex := os.join_path(stage, 'dex')
	os.mkdir_all(classes)!
	os.mkdir_all(dex)!
	mut compile := ['-source', java_bytecode, '-target', java_bytecode, '-Xlint:-options', '-cp',
		tools.android_jar, '-d', classes]
	compile << sources
	command(android_setting('JAVAC', 'javac'), compile)!
	mut files := os.walk_ext(classes, '.class')
	files.sort()
	mut dex_args := ['--min-api', minimum_android_api, '--lib', tools.android_jar, '--output',
		dex]
	dex_args << files
	command(os.join_path(tools.build_tools, 'd8'), dex_args)!
	copy(os.join_path(dex, 'classes.dex'), os.join_path(stage, 'classes.dex'))!
}

fn add_apk_entries(aapt string, stage string, unsigned string, entries []string) ! {
	current := os.getwd()
	os.chdir(stage)!
	defer { os.chdir(current) or {} }
	mut add := ['add', unsigned]
	add << entries
	command(aapt, add)!
}

fn sign_apk(tools AndroidTools, keystore string, unsigned string, aligned string, signed string) ! {
	command(os.join_path(tools.build_tools, 'zipalign'), ['-f', zip_alignment, unsigned, aligned])!
	if !os.is_file(keystore) {
		command('keytool', ['-genkeypair', '-keystore', keystore, '-storepass', 'android', '-keypass',
			'android', '-alias', 'androiddebugkey', '-dname', 'CN=Android Debug,O=Android,C=US',
			'-validity', '3650', '-keyalg', 'RSA', '-keysize', '2048', '-noprompt'])!
	}
	signer := os.join_path(tools.build_tools, 'apksigner')
	command(signer, ['sign', '--ks', keystore, '--ks-pass', 'pass:android', '--key-pass', 'pass:android',
		'--out', signed, aligned])!
	command(signer, ['verify', signed])!
}

fn deploy_android(tools AndroidTools, apk string) ! {
	badging := output(os.join_path(tools.build_tools, 'aapt'), ['dump', 'badging', apk])!
	mut package := ''
	mut activity := ''
	for line in badging.split_into_lines() {
		if line.starts_with("package: name='") {
			package = line.all_after("name='").all_before("'")
		} else if line.starts_with("launchable-activity: name='") {
			activity = line.all_after("name='").all_before("'")
		}
	}
	if package == '' || activity == '' {
		return error('The APK must declare a launcher activity')
	}
	command(tools.device.adb, tools.device.args(['install', '-r', apk]))!
	command(tools.device.adb, tools.device.args(['shell', 'am', 'start', '-n',
		'${package}/${activity}']))!
	println('Use adb logcat -s vimgui-android-demo:I to inspect lifecycle and taps.')
}

// android_demo builds either the external V UI or the native accessibility fixture.
pub fn android_demo(root string, accessible bool, args []string) ! {
	name := if accessible { 'run_android_accessible' } else { 'run_android_demo' }
	usage := 'Usage: v run scripts/${name}.vsh [run|--build-only]'
	if args in [['--help'], ['-h']] {
		println(usage)
		return
	}
	mode := if args.len == 0 { 'run' } else { args[0] }
	if args.len > 1 || mode !in ['run', '--build-only'] {
		return error_with_code(usage, 2)
	}
	deploy := mode == 'run'
	example := if accessible { 'android_accessible' } else { 'android_vulkan' }
	manifest := os.abs_path(android_setting('VIMGUI_ANDROID_MANIFEST',
		os.join_path(root, 'examples', example, 'AndroidManifest.xml')))
	ui := os.abs_path(android_setting('VIMGUI_ANDROID_UI_SOURCE',
		os.join_path(root, 'examples', 'android_vulkan', 'ui.v')))
	if !os.is_file(manifest) {
		return error_with_code('Cannot find the Android manifest: ${manifest}', 2)
	}
	if !accessible && !os.is_file(ui) && !os.is_dir(ui) {
		return error_with_code('Cannot find the V UI source: ${ui}', 2)
	}
	tools := android_tools(deploy, !accessible) or { return error_with_code(err.msg(), 2) }
	appui := accessible || os.getenv('VIMGUI_ANDROID_APPLICATION_UI') == '1'
	build_prefix := if accessible { 'android-accessible-' } else { 'android-onscreen-' }
	build := os.abs_path(android_setting('VIMGUI_ANDROID_BUILD_DIR',
		os.join_path(root, 'build', build_prefix + tools.abi.name)))
	configure_android(root, build, tools, accessible, appui)!
	if !accessible {
		build_widgets(root, build, ui, tools, appui)!
	}
	apk := package_android(root, build, manifest, tools, accessible)!
	println('APK: ${apk}')
	if deploy {
		deploy_android(tools, apk)!
	}
}

// Run device instrumentation with the same debug key used for the fixture.
pub fn android_accessibility_test(root string, args []string) ! {
	usage := 'Usage: v run scripts/test_android_accessible.vsh'
	if args in [['--help'], ['-h']] {
		println(usage)
		return
	}
	if args.len != 0 {
		return error_with_code(usage, 2)
	}
	tools := android_tools(true, false)!
	build := os.abs_path(android_setting('VIMGUI_ANDROID_BUILD_DIR',
		os.join_path(root, 'build', 'android-accessible-' + tools.abi.name)))
	manifest := os.join_path(root, 'examples', 'android_accessible', 'AndroidManifest.xml')
	configure_android(root, build, tools, true, true)!
	apk := package_android(root, build, manifest, tools, true)!
	stage := os.join_path(build, '.test-package-' + rand.uuid_v4())
	os.mkdir(stage, mode: 0o700)!
	defer { os.rmdir_all(stage) or {} }
	tests := os.join_path(root, 'tests', 'android', 'accessibility')
	compile_dex(stage, [os.join_path(tests, 'AccessibilitySmoke.java')], tools)!
	unsigned := os.join_path(stage, 'unsigned.apk')
	test_apk := os.join_path(build, 'test-package', 'test.apk')
	os.mkdir_all(os.dir(test_apk))!
	aapt := os.join_path(tools.build_tools, 'aapt')
	command(aapt, ['package', '-f', '-M', os.join_path(tests, 'AndroidManifest.xml'), '-I',
		tools.android_jar, '-F', unsigned])!
	add_apk_entries(aapt, stage, unsigned, ['classes.dex'])!
	sign_apk(tools, os.join_path(build, 'debug.keystore'), unsigned,
		os.join_path(stage, 'aligned.apk'), test_apk)!
	command(tools.device.adb, tools.device.args(['install', '-r', apk]))!
	command(tools.device.adb, tools.device.args(['install', '-r', test_apk]))!
	keycode_wakeup := '224'
	command(tools.device.adb, tools.device.args(['shell', 'input', 'keyevent', keycode_wakeup]))!
	command(tools.device.adb, tools.device.args(['shell', 'wm', 'dismiss-keyguard']))!
	mut invocation := [tools.device.adb]
	invocation << tools.device.args(['shell', 'am', 'instrument', '-w',
		'io.antono2.vimgui.accessible.test/io.antono2.vimgui.accessible.test.AccessibilitySmoke'])
	result := os.exec(invocation)
	log_path := os.join_path(build, 'instrumentation.log')
	os.write_file(log_path, result.output)!
	print(result.output)
	if result.exit_code != 0 || !result.output.contains('result=PASS:') {
		return error('Android accessibility instrumentation failed. See ${log_path}')
	}
}
