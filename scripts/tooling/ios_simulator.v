// Run keyboard and text-input render probes in an available iPhone Simulator.
module tooling

import os
import time

const ios_bundle_id = 'io.antono2.vimgui.ios-demo'
const metal_status_file = 'vimgui-metal-status.txt'
const frame_status_attempts = 30
const frame_status_poll_interval = time.second

struct SimulatorSmoke {
	argument string
	status   string
}

const simulator_smokes = [
	SimulatorSmoke{'--keyboard-smoke', 'keyboard_input_frame_completed'},
	SimulatorSmoke{'--composition-smoke', 'composition_frame_completed'},
	SimulatorSmoke{'--overflow-smoke', 'overflow_fallback_frame_completed'},
]

fn simulator_udid(listing string) ?string {
	for line in listing.split_into_lines() {
		if !line.trim_space().starts_with('iPhone ') {
			continue
		}
		// Device lines contain a UUID followed by a parenthesized boot state.
		for segment in line.split('(')[1..] {
			id := segment.all_before(')')
			if id.len == 36 && id.split('-').map(it.len) == [8, 4, 4, 4, 12]
				&& id.bytes().all(it.is_hex_digit() || it == `-`) {
				return id
			}
		}
	}
	return none
}

fn wait_for_simulator_frame(status_path string, smoke SimulatorSmoke) ! {
	for _ in 0 .. frame_status_attempts {
		if os.is_file(status_path) {
			status := os.read_file(status_path)!.trim_right('\r\n')
			println('iOS Simulator Metal status: ${status}')
			if status == smoke.status {
				return
			}
			return error('Expected ${smoke.status} for ${smoke.argument}')
		}
		time.sleep(frame_status_poll_interval)
	}
	return error('iOS Simulator ${smoke.argument} launched but no frame status was reported')
}

pub fn ios_simulator_smoke(args []string) ! {
	usage := 'Usage: v run scripts/run_ios_simulator_smoke.vsh path/to/vimgui_ios_demo.app'
	if args in [['--help'], ['-h']] {
		println(usage)
		return
	}
	if args.len != 1 || !os.is_dir(args[0]) {
		return error_with_code(usage, 2)
	}
	app := os.abs_path(args[0])
	listing := output('xcrun', ['simctl', 'list', 'devices', 'available'])!
	device := simulator_udid(listing) or {
		println('::warning::No available iPhone Simulator runtime; compile/link checks passed.')
		return
	}
	command('xcrun', ['simctl', 'boot', device])!
	defer {
		command('xcrun', ['simctl', 'shutdown', device]) or {}
	}
	command('xcrun', ['simctl', 'bootstatus', device, '-b'])!
	command('codesign', ['--force', '--sign', '-', os.join_path(app, 'Frameworks', 'libvimgui.dylib')])!
	command('codesign', ['--force', '--sign', '-', app])!
	command('xcrun', ['simctl', 'install', device, app])!
	container := output('xcrun', ['simctl', 'get_app_container', device, ios_bundle_id, 'data'])!
	status_path := os.join_path(container, 'tmp', metal_status_file)
	for index, smoke in simulator_smokes {
		if os.exists(status_path) {
			os.rm(status_path)!
		}
		command('xcrun', ['simctl', 'launch', device, ios_bundle_id, smoke.argument])!
		wait_for_simulator_frame(status_path, smoke)!
		if index < simulator_smokes.len - 1 {
			command('xcrun', ['simctl', 'terminate', device, ios_bundle_id])!
		}
	}
}
