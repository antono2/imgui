// Verifies repeated demo setup preserves installed pins and rejects a wrong revision.
module tooling

import os

fn test_install_modules_reuses_pinned_checkout() {
	workspace := os.join_path(os.temp_dir(), 'imgui-installed-pins-${os.getpid()}')
	root := os.join_path(workspace, 'project')
	modules := os.join_path(workspace, 'modules with spaces')
	installed := os.join_path(modules, 'antono2', 'fixture')
	saved := os.getenv('VMODULES')
	os.mkdir_all(root) or { panic(err) }
	os.mkdir_all(installed) or { panic(err) }
	defer {
		os.setenv('VMODULES', saved, true)
		os.rmdir_all(workspace) or {}
	}
	os.setenv('VMODULES', modules, true)
	os.write_file(os.join_path(root, 'v.mod'), "Module { name: 'fixture' dependencies: ['antono2.fixture@v1.0.0'] }\n") or { panic(err) }
	command('git', ['init', installed]) or { panic(err) }
	os.write_file(os.join_path(installed, 'fixture.txt'), 'original') or { panic(err) }
	command('git', ['-C', installed, 'add', '.']) or { panic(err) }
	command('git', ['-C', installed, '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-m', 'fixture']) or { panic(err) }
	command('git', ['-C', installed, 'tag', 'v1.0.0']) or { panic(err) }
	install_modules(root) or { panic(err) }
	install_modules(root) or { panic(err) }
	os.write_file(os.join_path(installed, 'fixture.txt'), 'local change') or { panic(err) }
	command('git', ['-C', installed, 'add', '.']) or { panic(err) }
	command('git', ['-C', installed, '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-m', 'local work']) or { panic(err) }
	head := output('git', ['-C', installed, 'rev-parse', 'HEAD']) or { panic(err) }
	install_modules(root) or {
		assert err.msg().contains('different revision')
		assert output('git', ['-C', installed, 'rev-parse', 'HEAD']) or { panic(err) } == head
		assert os.read_file(os.join_path(installed, 'fixture.txt')) or { panic(err) } == 'local change'
		return
	}
	assert false, 'Wrong installed revision was accepted'
}
