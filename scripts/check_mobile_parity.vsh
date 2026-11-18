// Compare the shared mobile sources on the standard and docking branches.
import os
import tooling

// Generated APIs and upstream submodules have different standard and docking revisions.
const shared_mobile_paths = [
	'.github/workflows/mobile-native.yml',
	'.gitmodules',
	'CMakeLists.txt',
	'build_vimgui.vsh',
	'imgui.c.v',
	'android',
	'docs/mobile.md',
	'examples/android_vulkan',
	'examples/ios_metal',
	'impl_android',
	'impl_ios',
	'impl_metal',
	'impl_mobile',
	'impl_osx',
	'native',
	'scripts/check_mobile_parity.sh',
	'scripts/check_mobile_parity.vsh',
	'scripts/run_android_demo.sh',
	'scripts/run_android_demo.vsh',
	'scripts/run_android_accessible.sh',
	'scripts/run_android_accessible.vsh',
	'scripts/test_android_accessible.sh',
	'scripts/test_android_accessible.vsh',
	'scripts/run_android_probes.sh',
	'scripts/run_android_probes.vsh',
	'scripts/run_ios_simulator_smoke.sh',
	'scripts/run_ios_simulator_smoke.vsh',
	'scripts/tooling',
	'scripts/build_appui.vsh',
	'scripts/check_prerequisites.vsh',
	'scripts/run_demo.vsh',
	'scripts/extract_zip.vsh',
	'scripts/setup_vulkan_ci.vsh',
	'setup.vsh',
	'.github/workflows/portable-tooling.yml',
	'tests/android',
	'tests/apple',
	'tests/desktop/moving_dependencies_smoke.v',
	'tests/input_text_callback.v',
	'tests/mobile',
	'tests/vulkan',
]

fn compare_mobile_branches(args []string) ! {
	usage := 'Usage: v run scripts/check_mobile_parity.vsh [MASTER_REF [STANDARD_REF]]'
	if args in [['--help'], ['-h']] {
		println(usage)
		return
	}
	if args.len > 2 {
		return error_with_code(usage, 2)
	}
	master := if args.len > 0 && args[0] != '' { args[0] } else { 'origin/master' }
	standard := if args.len > 1 && args[1] != '' { args[1] } else { 'origin/standard' }
	root := os.real_path(os.dir(@DIR))
	master_commit := tooling.output('git', ['-C', root, 'rev-parse', '--verify', '--end-of-options',
		master + '^{commit}'])!
	standard_commit := tooling.output('git', ['-C', root, 'rev-parse', '--verify', '--end-of-options',
		standard + '^{commit}'])!
	mut comparison := ['-C', root, 'diff', '--name-status', master_commit, standard_commit, '--']
	comparison << shared_mobile_paths
	changes := tooling.output('git', comparison)!
	if changes != '' {
		return error('Shared mobile integration differs between ${master} and ${standard}:\n${changes}')
	}
	println('Shared mobile integration matches between ${master} and ${standard}.')
}

compare_mobile_branches(os.args[1..]) or {
	eprintln(err)
	exit(if err.code() == 2 { 2 } else { 1 })
}
