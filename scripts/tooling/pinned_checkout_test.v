// Verify staged tagged checkouts preserve personal work and allow a failed clone to be retried.
module tooling

import os
import rand

fn test_pinned_checkout_reuse_and_recovery() {
	workspace := os.join_path(os.temp_dir(), 'imgui pinned modules ' + rand.uuid_v4())
	origin := os.join_path(workspace, 'local origin')
	namespace := os.join_path(workspace, 'modules with spaces', 'antono2')
	checkout := os.join_path(namespace, 'fixture')
	pin := 'v1.0.0'
	os.mkdir_all(origin) or { panic(err) }
	defer { os.rmdir_all(workspace) or {} }
	command('git', ['init', origin]) or { panic(err) }
	os.write_file(os.join_path(origin, 'fixture.txt'), 'original') or { panic(err) }
	command('git', ['-C', origin, 'add', '.']) or { panic(err) }
	command('git', ['-C', origin, '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
		'commit', '-m', 'fixture']) or { panic(err) }
	command('git', ['-C', origin, 'tag', pin]) or { panic(err) }
	mut rejected_missing := false
	prepare_pinned_checkout(os.join_path(workspace, 'missing origin'), pin, checkout) or {
		rejected_missing = true
	}
	assert rejected_missing
	assert os.ls(namespace) or { panic(err) } == []
	prepare_pinned_checkout(origin, pin, checkout) or { panic(err) }
	prepare_pinned_checkout(origin, pin, checkout) or { panic(err) }
	file := os.join_path(checkout, 'fixture.txt')
	os.write_file(file, 'personal changes') or { panic(err) }
	mut rejected_dirty := false
	prepare_pinned_checkout(origin, pin, checkout) or {
		rejected_dirty = err.msg().contains('Preserve local changes')
	}
	assert rejected_dirty
	assert os.read_file(file) or { panic(err) } == 'personal changes'
	assert os.ls(namespace) or { panic(err) } == ['fixture']
}
