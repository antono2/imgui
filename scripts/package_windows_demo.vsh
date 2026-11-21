// Assemble the relocatable Windows GLFW/Vulkan demo from its built runtime.
import flag
import os
import rand
import tooling

const runtime_files = ['v_imgui_demo.exe', 'vimgui.dll', 'glfw3.dll']
const runtime_file_mode = 0o755
const private_directory_mode = 0o700

fn package_demo(root string, output string, runtime string) !string {
	variant := tooling.demo_variant(root)!
	name := 'v-imgui-demo-${variant}-windows-x64'
	mut files := runtime_files.map(tooling.ZipFile{
		name: '${name}/${it}'
		path: os.join_path(runtime, it)
		mode: runtime_file_mode
	})
	files << [
		tooling.ZipFile{
			name: '${name}/README.txt'
			path: os.join_path(root, 'packaging', 'demo', 'windows', 'README.txt')
		},
		tooling.ZipFile{
			name: '${name}/VARIANT.txt'
			path: os.join_path(root, 'UPSTREAM_VARIANT')
		},
	]
	for file in files {
		if !os.is_file(file.path) || os.file_size(file.path) == 0 {
			return error('Missing or empty Windows demo package input: ${file.path}')
		}
	}
	os.mkdir_all(output)!
	stage := os.join_path(output, '.imgui-demo-' + rand.uuid_v4())
	os.mkdir(stage, mode: private_directory_mode)!
	defer { os.rmdir_all(stage) or {} }
	tooling.publish_demo_archive(output, stage, name, files)!
	return variant
}

fn run() ! {
	root := os.dir(@DIR)
	mut parser := flag.new_flag_parser(os.args[1..])
	parser.application('package_windows_demo')
	parser.description('Package a prebuilt GLFW/Vulkan demo for Windows x64.')
	runtime := parser.string('runtime-directory', 0, os.join_path(root, 'build', 'windows-demo'),
		'directory holding the demo executable and its two DLLs')
	output := parser.string('output-directory', 0, os.getwd(), 'directory for the finished ZIP')
	github_output := parser.string('github-output', 0, '',
		'append the selected variant to this GitHub Actions output file')
	if parser.bool('help', `h`, false, 'show this help') {
		println(parser.usage())
		return
	}
	if parser.finalize()!.len != 0 {
		return error(parser.usage())
	}
	variant := package_demo(root, os.abs_path(output), os.abs_path(runtime))!
	tooling.write_demo_variant(github_output, variant)!
}

run() or {
	eprintln(err)
	exit(1)
}
