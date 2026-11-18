// Verify that the whitespace exception applies only to the copied Dear ImGui tree.
import os
import rand

const baseline = 'baseline\n'
const copied = 'include/imgui/imgui.cpp'
const maintained = ['imgui.v', 'scripts/update_upstream.vsh', 'include/local.h']

fn checked(args []string) ! {
	result := os.exec(args)
	if result.exit_code != 0 {
		return error('${args.join(' ')} failed (exit ${result.exit_code})\n${result.output}')
	}
}

fn require(ok bool, reason string) ! {
	if !ok {
		return error(reason)
	}
}

fn run() ! {
	root := os.join_path(os.temp_dir(), 'imgui-whitespace-test-' + rand.uuid_v4())
	os.mkdir(root, mode: 0o700)!
	defer { os.rmdir_all(root) or {} }
	binary := os.join_path(root, 'check')
	checked([@VEXE, '-skip-running', '-o', binary, os.join_path(@DIR, 'check_update_whitespace.vsh')])!
	fixture := os.join_path(root, 'fixture')
	os.mkdir(fixture)!
	before := os.getwd()
	os.chdir(fixture)!
	defer { os.chdir(before) or {} }
	mut paths := [copied]
	paths << maintained
	for path in paths {
		os.mkdir_all(os.dir(path))!
		os.write_file(path, baseline)!
	}
	checked(['git', 'init', '--quiet'])!
	checked(['git', 'add', '.'])!
	checked(['git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', '-c',
		'commit.gpgsign=false', 'commit', '--quiet', '-m', 'fixture'])!
	checked([binary])!
	upstream := 'copied upstream text with spaces  \n\n'
	os.write_file(copied, upstream)!
	require(os.exec(['git', 'diff', '--check']).exit_code != 0, 'The fixture should contain whitespace Git can detect')!
	checked([binary])!
	require(os.read_file(copied)! == upstream, 'The copied text was changed')!
	for path in maintained {
		os.write_file(path, 'invalid trailing spaces  \n')!
		result := os.exec([binary])
		require(result.exit_code != 0 && result.output.contains(path), '${path} was not rejected by the whitespace check')!
		os.write_file(path, baseline)!
	}
	println('PASS: clean diff, copied whitespace, and ${maintained.len} maintained path checks')
}

run() or {
	eprintln(err)
	exit(1)
}
