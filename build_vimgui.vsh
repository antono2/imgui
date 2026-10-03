#!/usr/bin/env -S v run

import os

const repo_dir = @DIR

fn usage() {
	println('Usage: ./build_vimgui.vsh [--profile desktop|android-vulkan|apple-metal] [--linkage shared|static] [--glfw system|bundled] [--glfw-version VERSION] [--android-abi ABI] [--android-api LEVEL] [--ndk PATH] [--apple-sdk macosx|iphonesimulator|iphoneos] [--apple-arch ARCH] [--freetype off|system|bundled]')
}

fn option_value(args []string, index int, option string) string {
	if index + 1 >= args.len {
		eprintln('${option} requires a value')
		exit(2)
	}
	return args[index + 1]
}

fn run(parts []string) {
	command := parts.map(os.quoted_path(it)).join(' ')
	println('> ${command}')
	result := os.execute_or_exit(command)
	if result.output != '' {
		print(result.output)
		if !result.output.ends_with('\n') {
			println('')
		}
	}
}

mut linkage := os.getenv('VIMGUI_LINKAGE')

if linkage == '' {
	linkage = 'shared'
}

mut glfw_provider := os.getenv('VIMGUI_GLFW_PROVIDER')

if glfw_provider == '' {
	glfw_provider = 'system'
}

mut glfw_version := os.getenv('VIMGUI_GLFW_VERSION')

if glfw_version == '' {
	glfw_version = '3.3'
}

mut profile := os.getenv('VIMGUI_PROFILE')
if profile == '' {
	profile = 'desktop'
}
mut android_abi := os.getenv('ANDROID_ABI')
if android_abi == '' {
	android_abi = 'armeabi-v7a'
}
mut android_api := os.getenv('ANDROID_API')
if android_api == '' {
	android_api = '24'
}
mut ndk_dir := os.getenv('ANDROID_NDK_HOME')
if ndk_dir == '' {
	ndk_dir = os.getenv('ANDROID_NDK_ROOT')
}
mut freetype := os.getenv('VIMGUI_FREETYPE')
if freetype == '' {
	freetype = 'off'
}
mut apple_sdk := os.getenv('VIMGUI_APPLE_SDK')
if apple_sdk == '' {
	apple_sdk = 'macosx'
}
mut apple_arch := os.getenv('VIMGUI_APPLE_ARCH')
if apple_arch == '' {
	apple_arch = 'arm64'
}

args := os.args[1..]

mut index := 0

for index < args.len {
	match args[index] {
		'--profile' {
			profile = option_value(args, index, '--profile')
			index += 2
		}
		'--linkage' {
			linkage = option_value(args, index, '--linkage')
			index += 2
		}
		'--glfw' {
			glfw_provider = option_value(args, index, '--glfw')
			index += 2
		}
		'--glfw-version' {
			glfw_version = option_value(args, index, '--glfw-version')
			index += 2
		}
		'--android-abi' {
			android_abi = option_value(args, index, '--android-abi')
			index += 2
		}
		'--android-api' {
			android_api = option_value(args, index, '--android-api')
			index += 2
		}
		'--ndk' {
			ndk_dir = option_value(args, index, '--ndk')
			index += 2
		}
		'--freetype' {
			freetype = option_value(args, index, '--freetype')
			index += 2
		}
		'--apple-sdk' {
			apple_sdk = option_value(args, index, '--apple-sdk')
			index += 2
		}
		'--apple-arch' {
			apple_arch = option_value(args, index, '--apple-arch')
			index += 2
		}
		'-h', '--help' {
			usage()
			exit(0)
		}
		else {
			eprintln('Unknown option: ${args[index]}')
			usage()
			exit(2)
		}
	}
}

if linkage !in ['shared', 'static'] {
	eprintln('linkage must be shared or static')
	exit(2)
}

if profile !in ['desktop', 'android-vulkan', 'apple-metal'] {
	eprintln('profile must be desktop, android-vulkan, or apple-metal')
	exit(2)
}
if profile == 'apple-metal' {
	if apple_sdk !in ['macosx', 'iphonesimulator', 'iphoneos'] {
		eprintln('apple-sdk must be macosx, iphonesimulator, or iphoneos')
		exit(2)
	}
	if apple_arch !in ['arm64', 'x86_64'] || (apple_sdk == 'iphoneos' && apple_arch != 'arm64') {
		eprintln('unsupported Apple SDK/architecture combination')
		exit(2)
	}
}

if freetype !in ['off', 'system', 'bundled'] {
	eprintln('freetype must be off, system, or bundled')
	exit(2)
}

if profile == 'android-vulkan' {
	if android_abi !in ['armeabi-v7a', 'arm64-v8a', 'x86_64'] {
		eprintln('unsupported Android ABI: ${android_abi}')
		exit(2)
	}
	if ndk_dir == '' || !os.is_file(os.join_path(ndk_dir, 'build', 'cmake', 'android.toolchain.cmake')) {
		eprintln('Android NDK not found; pass --ndk PATH or set ANDROID_NDK_HOME')
		exit(2)
	}
	if android_api.int() < 24 {
		eprintln('Android API level must be at least 24 for Vulkan')
		exit(2)
	}
}

if glfw_provider !in ['system', 'bundled'] {
	eprintln('glfw provider must be system or bundled')
	exit(2)
}

if !os.is_file(os.join_path(repo_dir, 'CMakeLists.txt'))
	|| !os.is_file(os.join_path(repo_dir, 'cimgui', 'cimgui.cpp'))
	|| !os.is_file(os.join_path(repo_dir, 'cimplot', 'cimplot.cpp')) {
	eprintln('Missing cimgui or cimplot sources. Run `v run generate.vsh` first (or initialise the submodules).')
	exit(1)
}

static_build := if linkage == 'static' { 'ON' } else { 'OFF' }

mut no_export := 'ON'

$if windows {
	// A Windows DLL needs cimgui/cimplot API exports and an import library.
	no_export = 'OFF'
}

build_type := if os.getenv('CMAKE_BUILD_TYPE') == '' {
	'Release'
} else {
	os.getenv('CMAKE_BUILD_TYPE')
}

safe_glfw_version := glfw_version.replace('..', '_').replace('/', '_').replace('\\', '_')
suffix := if freetype == 'off' { '' } else { '-freetype' }
build_name := if profile == 'desktop' {
	'${linkage}-${glfw_provider}-${safe_glfw_version}${suffix}'
} else if profile == 'apple-metal' {
	'${profile}-${apple_sdk}-${apple_arch}-${linkage}${suffix}'
} else {
	'${profile}-${android_abi}-api${android_api}-${linkage}${suffix}'
}
build_dir := os.join_path(repo_dir, 'build', build_name)
base_output_dir := if profile == 'desktop' {
	os.join_path(repo_dir, 'lib')
} else if profile == 'apple-metal' {
	os.join_path(repo_dir, 'lib', profile, apple_sdk, apple_arch)
} else {
	os.join_path(repo_dir, 'lib', profile, android_abi)
}
output_dir := if freetype == 'off' {
	base_output_dir
} else {
	os.join_path(base_output_dir, 'freetype')
}

os.mkdir_all(build_dir) or {
	eprintln('Could not create build directory ${build_dir}: ${err}')
	exit(1)
}
mut configure_args := [
	'cmake',
	'-S',
	repo_dir,
	'-B',
	build_dir,
	'-DVIMGUI_OUTPUT_DIR=${output_dir}',
	'-DVIMGUI_PROFILE=${profile}',
	'-DSTATIC_BUILD=${static_build}',
	'-DVIMGUI_GLFW_PROVIDER=${glfw_provider}',
	'-DVIMGUI_GLFW_VERSION=${glfw_version}',
	'-DCMAKE_BUILD_TYPE=${build_type}',
	'-DCIMGUI_NO_EXPORT=${no_export}',
	'-DIMGUI_FREETYPE=${if freetype == 'off' { 'OFF' } else { 'ON' }}',
	'-DVIMGUI_FREETYPE_PROVIDER=${if freetype == 'off' { 'system' } else { freetype }}',
]
if profile == 'android-vulkan' {
	configure_args << '-DCMAKE_TOOLCHAIN_FILE=${os.join_path(ndk_dir, 'build', 'cmake', 'android.toolchain.cmake')}'
	configure_args << '-DANDROID_ABI=${android_abi}'
	configure_args << '-DANDROID_PLATFORM=android-${android_api}'
	configure_args << '-DANDROID_STL=c++_static'
}
if profile == 'apple-metal' {
	if apple_sdk != 'macosx' {
		configure_args << '-DCMAKE_SYSTEM_NAME=iOS'
	}
	configure_args << '-DCMAKE_OSX_SYSROOT=${apple_sdk}'
	configure_args << '-DCMAKE_OSX_ARCHITECTURES=${apple_arch}'
	configure_args << '-DCMAKE_OSX_DEPLOYMENT_TARGET=${if apple_sdk == 'macosx' {
		'11.0'
	} else {
		'13.0'
	}}'
}
run(configure_args)
run(['cmake', '--build', build_dir, '--config', build_type, '--parallel'])
println('Built vimgui in ${output_dir} (profile: ${profile}, linkage: ${linkage}, freetype: ${freetype})')
