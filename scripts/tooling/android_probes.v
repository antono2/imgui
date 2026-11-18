// Build and run the native device and offscreen Vulkan probes on Android.
module tooling

import os
import rand

pub fn android_probes(root string, args []string) ! {
	usage := 'Usage: v run scripts/run_android_probes.vsh [--build-only]'
	if args in [['--help'], ['-h']] {
		println(usage)
		return
	}
	build_only := args == ['--build-only']
	if args.len != 0 && !build_only {
		return error_with_code(usage, 2)
	}
	ndk := android_setting('ANDROID_NDK_HOME', os.getenv('ANDROID_NDK_ROOT'))
	toolchain := android_toolchain(ndk) or { return error_with_code(err.msg(), 2) }
	sdk := android_setting('ANDROID_SDK_ROOT', os.getenv('ANDROID_HOME'))
	device := if build_only {
		AndroidDevice{}
	} else {
		android_device(sdk) or { return error_with_code(err.msg(), 2) }
	}
	abi := if build_only {
		os.getenv('ANDROID_ABI')
	} else {
		device.abi() or { return error_with_code(err.msg(), 2) }
	}
	if abi !in supported_abis {
		if build_only {
			return error_with_code('Set ANDROID_ABI to armeabi-v7a, arm64-v8a or x86_64', 2)
		}
		return error_with_code('Unsupported or disconnected Android device ABI: ${abi}', 2)
	}
	build := os.abs_path(android_setting('VIMGUI_ANDROID_BUILD_DIR',
		os.join_path(root, 'build', 'android-device-probe-' + abi)))
	command('cmake', ['-S', root, '-B', build, '-G', 'Ninja', '-DCMAKE_TOOLCHAIN_FILE=${toolchain}',
		'-DANDROID_ABI=${abi}', '-DANDROID_PLATFORM=android-${minimum_android_api}',
		'-DANDROID_STL=c++_static', '-DVIMGUI_PROFILE=android-vulkan', '-DIMGUI_FREETYPE=ON',
		'-DVIMGUI_FREETYPE_PROVIDER=bundled', '-DVIMGUI_BUILD_SMOKE_TESTS=ON', '-DSTATIC_BUILD=OFF',
		'-DCMAKE_BUILD_TYPE=Release'])!
	command('cmake', ['--build', build, '--parallel', '4'])!
	if build_only {
		return
	}

	// Each run owns its files on the device, even when builds share one adb server.
	remote := '/data/local/tmp/io.antono2.vimgui.probe/' + rand.uuid_v4()
	command(device.adb, device.args(['shell', 'mkdir', '-p', remote]))!
	defer {
		command(device.adb, device.args(['shell', 'rm', '-r', remote])) or {}
	}
	command(device.adb, device.args(['push', os.join_path(build, 'lib', native_library),
		remote + '/' + native_library]))!
	for probe in ['vimgui_android_device_probe', 'vimgui_vulkan_offscreen_probe'] {
		remote_executable := remote + '/' + probe
		command(device.adb, device.args(['push', os.join_path(build, probe), remote_executable]))!
		command(device.adb, device.args(['shell', 'chmod', '755', remote_executable]))!
		command(device.adb, device.args(['shell', 'LD_LIBRARY_PATH=${remote} ${remote_executable}']))!
	}
}
