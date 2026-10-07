#!/usr/bin/env -S v run
// Prepares the Vulkan SDK dependencies used by CI builds.

import os
import json2
import tooling

struct Driver {
	library_path string
	api_version  string = '1.0.5'
}

struct DriverManifest {
	file_format_version string = '1.0.0'
	icd                 Driver @[json: 'ICD']
}

fn append_environment(path string, lines []string) ! {
	if path == '' {
		return error('GitHub environment file is not configured')
	}
	mut file := os.open_append(path)!
	defer { file.close() }
	file.writeln(lines.join('\n'))!
}

fn run() ! {
	if os.args[1..] == ['--help'] || os.args[1..] == ['-h'] {
		println('Usage: ./scripts/setup_vulkan_ci.vsh SDK_VERSION ARTIFACT_TAG\nDownloads SDK and SwiftShader artifacts for GitHub Actions runners.')
		return
	}
	if os.args.len != 3 {
		return error('Usage: ./scripts/setup_vulkan_ci.vsh SDK_VERSION ARTIFACT_TAG')
	}
	version := os.args[1]
	tag := os.args[2]
	if os.getenv('RUNNER_TEMP') == '' {
		return error('RUNNER_TEMP is not configured')
	}
	mut platform := ''
	mut driver := ''
	match os.getenv('RUNNER_OS') {
		'Linux' {
			platform = 'ubuntu-20.04-x64'
			driver = 'libvk_swiftshader.so'
		}
		'macOS' {
			platform = 'macOS-13-x64'
			driver = 'libvk_swiftshader.dylib'
		}
		'Windows' {
			platform = 'windows-2022-x64'
			driver = 'vk_swiftshader.dll'
		}
		else {
			return error('Unsupported runner OS: ${os.getenv('RUNNER_OS')}')
		}
	}
	root := os.join_path(os.getenv('RUNNER_TEMP'), 'vulkan-ci')
	sdk_root := os.join_path(root, 'VulkanSDK')
	driver_root := os.join_path(root, 'swiftshader')
	os.mkdir_all(root)!
	for name, destination in {
		'vulkanSDK-${version}-${platform}.zip': sdk_root
		'swiftshader-${platform}.zip':          driver_root
	} {
		archive := os.join_path(root, name)
		tooling.command('curl', ['--fail', '--location', '--retry', '5', '--retry-all-errors',
			'--silent', '--show-error',
			'https://github.com/NcStudios/VulkanCI/releases/download/${tag}/${name}', '--output',
			archive])!
		tooling.extract_zip(archive, destination)!
	}
	sdk := os.join_path(sdk_root, version)
	if !os.is_dir(os.join_path(sdk, 'include')) || !os.is_file(os.join_path(driver_root, driver)) {
		return error('Vulkan CI artifacts have an unexpected layout')
	}
	manifest := os.join_path(driver_root, 'vk_swiftshader_icd.json')
	os.write_file(manifest, json2.encode(DriverManifest{ icd: Driver{ library_path: os.join_path(driver_root, driver) } }, escape_unicode: true))!
	mut variables := ['VULKAN_SDK=${sdk}', 'VULKAN_SDK_VERSION=${version}',
		'VK_DRIVER_FILES=${manifest}']
	match os.getenv('RUNNER_OS') {
		'Windows' {
			variables << 'VK_LAYER_PATH=${os.join_path(sdk, 'bin')}'
			append_environment(os.getenv('GITHUB_PATH'), [os.join_path(sdk, 'bin')])!
		}
		else {
			variables << 'VK_LAYER_PATH=${os.join_path(sdk, 'share', 'vulkan', 'explicit_layer.d')}'
			key := if os.getenv('RUNNER_OS') == 'Linux' {
				'LD_LIBRARY_PATH'
			} else {
				'DYLD_LIBRARY_PATH'
			}
			prior := if os.getenv(key) == '' { '' } else { os.getenv(key) + ':' }
			variables << '${key}=${prior}${os.join_path(sdk, 'lib')}:${driver_root}'
		}
	}
	append_environment(os.getenv('GITHUB_ENV'), variables)!
}

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}
