// Render a bounded number of frames and preserve the demo's diagnostics.
import flag
import os
import time

const default_frames = 60
const max_frames = 10_000
const default_timeout_seconds = 60
const max_timeout_seconds = 300
const output_poll_interval = 20 * time.millisecond
const render_failures = ['vuid-', 'validation error', 'segmentation', 'assert', 'fatal']

fn smoke(directory string, frames int, timeout time.Duration) ! {
	player := os.join_path(directory, 'v_imgui_demo.exe')
	if !os.is_file(player) {
		return error('Build the demo first with scripts\\setup_windows.ps1: ${player}')
	}
	stdout_path := os.join_path(directory, 'smoke-stdout.log')
	stderr_path := os.join_path(directory, 'smoke-stderr.log')
	mut stdout_file := os.create(stdout_path)!
	defer { stdout_file.close() }
	mut stderr_file := os.create(stderr_path)!
	defer { stderr_file.close() }

	mut environment := os.environ()
	environment['VIMGUI_SMOKE_FRAMES'] = frames.str()
	mut child := os.new_process(player)
	child.set_work_folder(directory)
	child.set_environment(environment)
	child.set_redirect_stdio()
	child.run()
	defer {
		if child.is_alive() {
			child.signal_kill()
			// wait() reaps the killed process only while its status is running.
			child.status = .running
		}
		child.wait()
		child.close()
	}
	timer := time.new_stopwatch()
	for {
		live := child.is_alive()
		out := child.stdout_read()
		diagnostics := child.stderr_read()
		stdout_file.write_string(out)!
		stderr_file.write_string(diagnostics)!
		if !live && out == '' && diagnostics == '' {
			break
		}
		if timer.elapsed() >= timeout {
			return error('Windows demo rendering timed out after ${timeout}; inspect ${stdout_path} and ${stderr_path}.')
		}
		if out == '' && diagnostics == '' { time.sleep(output_poll_interval) }
	}
	child.wait()
	// Inspect complete streams so diagnostics split across pipe reads are detected.
	stdout_file.flush()
	stderr_file.flush()
	out := os.read_file(stdout_path)!
	diagnostics := os.read_file(stderr_path)!
	print(out)
	eprint(diagnostics)
	output_lower := out.to_lower()
	diagnostics_lower := diagnostics.to_lower()
	if child.code != 0 || render_failures.any(output_lower.contains(it)
		|| diagnostics_lower.contains(it)) {
		return error('Windows demo rendering failed (exit ${child.code}); inspect ${stdout_path} and ${stderr_path}.')
	}
	println('Windows GLFW/Vulkan demo rendered and shut down after ${frames} frames.')
}

fn run(args []string) ! {
	mut parser := flag.new_flag_parser(args)
	parser.application('smoke_windows_demo')
	parser.description('Render the built GLFW/Vulkan demo and check for a clean shutdown.')
	directory := parser.string('demo-directory', 0, os.join_path(os.dir(@DIR), 'build',
		'windows-demo'), 'directory containing v_imgui_demo.exe')
	frames := parser.int('frames', 0, default_frames, 'number of frames to render')
	seconds := parser.int('timeout-seconds', 0, default_timeout_seconds, 'render time limit in seconds')
	if parser.bool('help', `h`, false, 'show this help') {
		println(parser.usage())
		return
	}
	if parser.finalize()!.len != 0 {
		return error(parser.usage())
	}
	if frames < 1 || frames > max_frames {
		return error('--frames must be between 1 and ${max_frames}.')
	}
	if seconds < 1 || seconds > max_timeout_seconds {
		return error('--timeout-seconds must be between 1 and ${max_timeout_seconds}.')
	}
	smoke(os.abs_path(directory), frames, seconds * time.second)!
}

run(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
