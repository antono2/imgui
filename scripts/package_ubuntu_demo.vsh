// Assemble and optionally render-test the relocatable Ubuntu demo archive.
import crypto.sha256
import flag
import os
import rand
import tooling

const demo_executable = 'v_imgui_demo'
const system_libraries = '/usr/lib/x86_64-linux-gnu'
const bundled_libraries = ['libvimgui.so', 'libglfw.so.3', 'libstdc++.so.6', 'libgcc_s.so.1']
const executable_mode = 0o755
const data_mode = 0o644

fn command(args []string) !string {
	result := os.exec(args)
	if result.exit_code != 0 {
		return error('${args[0]} exited with status ${result.exit_code}\n${result.output}')
	}
	return result.output
}

fn stage_file(source string, destination string, mode int) ! {
	os.cp(source, destination)!
	os.chmod(destination, mode)!
}

fn check_bundle(player string, library string, library_directory string) ! {
	if command(['patchelf', '--print-rpath', player])!.trim_space() != r'$ORIGIN/lib'
		|| command(['patchelf', '--print-rpath', library])!.trim_space() != r'$ORIGIN' {
		return error('The package does not have relative library paths')
	}
	loader := command(['env', '-u', 'LD_LIBRARY_PATH', 'ldd', player])!
	if loader.contains('not found') {
		return error('The demo has unresolved libraries:\n${loader}')
	}
	for name in bundled_libraries {
		if !loader.contains(os.join_path(library_directory, name)) {
			return error('The demo does not load ${name} from its package')
		}
	}
}

fn check_render(player string, directory string) ! {
	// ImGui saves window settings in the working directory.
	previous := os.getwd()
	os.chdir(directory)!
	defer { os.chdir(previous) or {} }
	// A bounded draw run exercises the actual executable with the package loader paths.
	log := command(['env', '-u', 'LD_LIBRARY_PATH', 'VIMGUI_SMOKE_FRAMES=60', 'timeout', '60s',
		'xvfb-run', '-a', player])!
	print(log)
	diagnostics := log.to_lower()
	for failure in ['vuid-', 'validation error', 'segmentation', 'assert', 'fatal'] {
		if diagnostics.contains(failure) {
			return error('The packaged demo reported a rendering failure: ${failure}')
		}
	}
}

fn package_demo(root string, output string, player string, imgui string, smoke bool) !string {
	variant_file := os.join_path(root, 'UPSTREAM_VARIANT')
	variant := os.read_file(variant_file)!.trim_space()
	if variant !in ['docking', 'standard'] {
		return error('Unsupported ImGui variant: ${variant}')
	}
	if os.user_os() != 'linux' {
		return error('Ubuntu demo packaging requires Linux')
	}
	os.mkdir_all(output)!
	stage := os.join_path(output, '.imgui-demo-' + rand.uuid_v4())
	os.mkdir(stage, mode: 0o700)!
	defer { os.rmdir_all(stage) or {} }
	name := 'v-imgui-demo-${variant}-ubuntu24-amd64'
	directory := os.join_path(stage, name)
	libraries := os.join_path(directory, 'lib')
	os.mkdir_all(libraries)!
	staged_player := os.join_path(directory, demo_executable)
	staged_imgui := os.join_path(libraries, 'libvimgui.so')
	stage_file(player, staged_player, executable_mode)!
	stage_file(imgui, staged_imgui, executable_mode)!
	for library_name in bundled_libraries[1..] {
		stage_file(os.join_path(system_libraries, library_name), os.join_path(libraries,
			library_name), executable_mode)!
	}
	stage_file(os.join_path(root, 'packaging', 'demo', 'ubuntu24', 'README.txt'), os.join_path(directory,
		'README.txt'), data_mode)!
	stage_file(variant_file, os.join_path(directory, 'VARIANT.txt'), data_mode)!
	launcher := os.join_path(root, 'packaging', 'demo', 'ubuntu24', 'run.sh')
	// Keep the compatibility launcher for branches that ship it.
	if os.is_file(launcher) {
		stage_file(launcher, os.join_path(directory, 'run.sh'), executable_mode)!
	}
	command(['strip', '--strip-unneeded', staged_player, staged_imgui])!
	command(['patchelf', '--set-rpath', r'$ORIGIN/lib', staged_player])!
	command(['patchelf', '--set-rpath', r'$ORIGIN', staged_imgui])!
	check_bundle(staged_player, staged_imgui, libraries)!
	if smoke {
		check_render(staged_player, stage)!
	}
	archive_name := name + '.zip'
	temporary_archive := os.join_path(stage, archive_name)
	mut files := []tooling.ZipFile{}
	mut paths := os.walk_ext(directory, '')
	paths.sort()
	for path in paths {
		info := os.stat(path)!
		files << tooling.ZipFile{
			name: name + '/' + path[directory.len + 1..]
			path: path
			mode: info.mode
		}
	}
	tooling.write_zip(temporary_archive, files)!
	tooling.verify_written_zip(temporary_archive, files, os.join_path(stage, 'verify-entry'))!
	checksum := sha256.sum(os.read_bytes(temporary_archive)!).hex()
	os.mv(temporary_archive, os.join_path(output, archive_name))!
	println('${checksum}  ${archive_name}')
	return variant
}

fn run() ! {
	root := os.dir(@DIR)
	mut parser := flag.new_flag_parser(os.args[1..])
	parser.application('package_ubuntu_demo')
	parser.description('Package a prebuilt GLFW/Vulkan demo for Ubuntu 24.04.')
	player := parser.string('player', 0, os.join_path(root, 'build', 'desktop-demo',
		demo_executable), 'prebuilt demo executable')
	library := parser.string('imgui-library', 0, os.join_path(root, 'lib', 'libvimgui.so'),
		'compiled native ImGui library')
	output := parser.string('output-directory', 0, os.getwd(), 'directory for the finished ZIP')
	github_output := parser.string('github-output', 0, '',
		'append the selected variant to this GitHub Actions output file')
	smoke := parser.bool('smoke', 0, false, 'render 60 frames on a private Xvfb display')
	if parser.bool('help', `h`, false, 'show this help') {
		println(parser.usage())
		return
	}
	if parser.finalize()!.len != 0 {
		return error(parser.usage())
	}
	variant := package_demo(root, os.abs_path(output), os.abs_path(player), os.abs_path(library),
		smoke)!
	if github_output != '' {
		mut receipt := os.open_append(github_output)!
		defer { receipt.close() }
		receipt.writeln('name=${variant}')!
	}
}

run() or {
	eprintln(err)
	exit(1)
}
