// Checks standalone demo module discovery without relying on the user's installed ImGui.
module tooling

import os

fn test_demo_resolves_renamed_checkout_and_submodules() {
	workspace := os.join_path(os.temp_dir(), 'imgui-demo-path-${os.getpid()}')
	root := os.join_path(workspace, 'renamed checkout')
	runtime := os.join_path(workspace, 'runtime')
	os.mkdir_all(os.join_path(root, 'backend')) or { panic(err) }
	defer {
		// Remove the directory link itself before recursively cleaning fixtures.
		module_link := os.join_path(runtime, 'modules', 'antono2', 'imgui')
		$if windows {
			os.rmdir(module_link) or {}
		} $else {
			os.rm(module_link) or {}
		}
		os.rmdir_all(workspace) or {}
	}
	os.write_file(os.join_path(root, 'v.mod'), "Module { name: 'antono2.imgui' }\n") or { panic(err) }
	os.write_file(os.join_path(root, 'api.v'), 'module imgui\npub fn value() int { return 17 }\n') or { panic(err) }
	os.write_file(os.join_path(root, 'backend', 'api.v'), 'module backend\npub fn value() int { return 23 }\n') or { panic(err) }
	main := os.join_path(workspace, 'main.v')
	os.write_file(main, 'import antono2.imgui\nimport antono2.imgui.backend\nfn main() { assert imgui.value() == 17; assert backend.value() == 23 }\n') or { panic(err) }
	path := demo_module_path(root, runtime) or { panic(err) }
	assert demo_module_path(root, runtime) or { panic(err) } == path
	command(compiler(), ['-old-compiler', '-path', path, 'run', main]) or { panic(err) }
	other := os.join_path(workspace, 'another checkout')
	os.mkdir_all(other) or { panic(err) }
	demo_module_path(other, runtime) or {
		assert err.msg().contains('points elsewhere')
		assert os.read_file(os.join_path(root, 'api.v')) or { panic(err) } != ''
		return
	}
	assert false, 'A conflicting module link was silently replaced'
}
