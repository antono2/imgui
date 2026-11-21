// Run the Android CI package, architecture, and export checks with the installed SDK.
module tooling

import os

const ci_android_api = '36'
const ci_ndk_version = '27.3.13750724'
const ci_arm_abi = 'armeabi-v7a'
const apk_bytecode_entry = 'classes.dex'
const android_ci_usage_status = 2
const android_ci_usage = 'Usage: v run scripts/check_android.vsh install | java SCRATCH | probes | arm-link SCRATCH | demo | accessible'

fn require_artifacts(build string, names []string) ! {
	for name in names {
		path := os.join_path(build, name)
		if !os.is_file(path) {
			return error('Missing Android build artifact: ${path}')
		}
	}
}

fn require_exports(tools AndroidTools, library string, exports []string) ! {
	nm := os.join_path(os.dir(tools.clang), 'llvm-nm')
	symbols := output(nm, ['-D', '--defined-only', library])!.fields()
	for name in exports {
		if name !in symbols {
			return error('Missing Android export ${name} in ${library}')
		}
	}
	println('Verified exports in ${library}: ${exports.join(', ')}')
}

fn java_bridge(root string, sdk string, scratch string) ! {
	os.mkdir_all(scratch)!
	jar := os.join_path(sdk, 'platforms', 'android-' + ci_android_api, 'android.jar')
	command('javac', ['-source', java_bytecode, '-target', java_bytecode, '-cp', jar, '-d', scratch,
		os.join_path(root, 'android', 'java', 'io', 'antono2', 'imgui', 'ImGuiInputView.java')])!
}

fn arm_link(root string, build string, scratch string, tools AndroidTools) ! {
	if tools.abi.name != ci_arm_abi {
		return error('The ARM link check requires ANDROID_ABI=${ci_arm_abi}.')
	}
	modules := demo_module_path(root, scratch)!
	probe := os.join_path(scratch, 'vimgui-v-android-smoke')
	profile := os.join_path(root, 'lib', 'android-vulkan', ci_arm_abi, 'freetype')
	copy(os.join_path(build, 'lib', native_library), os.join_path(profile, native_library))!
	command(compiler(), ['-path', modules, '-os', 'android', '-arch', tools.abi.v_arch, '-cc',
		tools.clang, '-d', 'use_freetype', '-gc', 'none', '-no-memory-limit', '-o', probe,
		os.join_path(root, 'tests', 'android', 'v_api_link_smoke.v')])!
	header := output(os.join_path(os.dir(tools.clang), 'llvm-readelf'), ['-h', probe])!
	lines := header.split_into_lines().map(it.trim_space())
	if !lines.any(it.starts_with('Class:') && it.all_after(':').trim_space() == 'ELF32')
		|| !lines.any(it.starts_with('Machine:') && it.all_after(':').trim_space() == 'ARM') {
		return error('Expected a 32-bit ARM executable: ${probe}')
	}
	println('Verified 32-bit ARM executable: ${probe}')
}

pub fn android_ci(root string, args []string) ! {
	if args in [['--help'], ['-h']] {
		println(android_ci_usage)
		return
	}
	if args == ['install'] {
		command('sdkmanager', ['--install', 'ndk;${ci_ndk_version}',
			'platforms;android-${ci_android_api}'])!
		return
	}
	if args.len == 0 || args.any(it == '') {
		return error_with_code(android_ci_usage, android_ci_usage_status)
	}
	mode := args[0]
	if (mode in ['java', 'arm-link'] && args.len != 2)
		|| (mode in ['probes', 'demo', 'accessible'] && args.len != 1)
		|| mode !in ['java', 'arm-link', 'probes', 'demo', 'accessible'] {
		return error_with_code(android_ci_usage, android_ci_usage_status)
	}
	sdk := android_setting('ANDROID_SDK_ROOT', os.getenv('ANDROID_HOME'))
	if sdk == '' {
		return error('Set ANDROID_SDK_ROOT to the installed Android SDK.')
	}
	if mode == 'java' {
		java_bridge(root, os.abs_path(sdk), os.abs_path(args[1]))!
		return
	}
	ndk := android_setting('ANDROID_NDK_HOME', os.join_path(sdk, 'ndk', ci_ndk_version))
	os.setenv('ANDROID_NDK_HOME', os.abs_path(ndk), true)
	tools := android_tools(false, mode != 'accessible')!
	abi := tools.abi.name
	default_build := if mode == 'accessible' {
		os.join_path(root, 'build', 'android-accessible-${abi}')
	} else {
		os.join_path(root, 'build', 'ci-android')
	}
	build := os.abs_path(android_setting('VIMGUI_ANDROID_BUILD_DIR', default_build))
	os.setenv('VIMGUI_ANDROID_BUILD_DIR', build, true)
	library := os.join_path(build, 'lib', native_library)
	match mode {
		'probes' {
			android_probes(root, ['--build-only'])!
			require_artifacts(build, ['lib/${native_library}', 'libvimgui_android_link_smoke.so',
				'vimgui_android_device_probe', 'vimgui_vulkan_offscreen_probe'])!
			require_exports(tools, library, ['vimgui_android_init',
				'vimgui_android_set_clipboard_context', 'vimgui_android_apply_text_edit',
				'Java_io_antono2_imgui_ImGuiInputView_nativeCommitText'])!
		}
		'arm-link' {
			arm_link(root, build, os.abs_path(args[1]), tools)!
		}
		'demo' {
			android_demo(root, false, ['--build-only'])!
			apk := os.join_path(build, 'vimgui-demo-${abi}.apk')
			require_zip_files(apk, [apk_bytecode_entry, 'lib/${abi}/${activity_library}',
				'lib/${abi}/${widget_library}'])!
			require_exports(tools, os.join_path(build, widget_library), [
				'vimgui_android_demo_draw_ui',
			])!
			println('Verified required entries in ${apk}')
		}
		else {
			check := os.join_path(root, 'scripts', 'test_android_accessible.vsh')
			command(compiler(), ['-check', check])!
			android_demo(root, true, ['--build-only'])!
			apk := os.join_path(build, 'accessible-${abi}.apk')
			require_zip_files(apk, [apk_bytecode_entry])!
			println('Verified required entries in ${apk}')
		}
	}
}
