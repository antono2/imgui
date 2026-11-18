// Publish staged generated files only when their Git tree changed.
import flag
import os
import rand

const bot_name = 'github-actions[bot]'
const bot_email = '41898282+github-actions[bot]@users.noreply.github.com'

struct Proposal {
	ref      string
	expected string
	needed   bool
}

fn git(repo string, args []string) !string {
	command := 'git -C ${os.quoted_path(repo)} ' + args.map(os.quoted_path(it)).join(' ')
	result := os.execute(command)
	if result.exit_code != 0 {
		return error('git ${args[0]} failed: ${result.output.trim_space()}')
	}
	return result.output.trim_space()
}

fn remote_head(repo string, ref string) !string {
	// An absent ref gives an empty result; network and auth failures still fail.
	reply := git(repo, ['ls-remote', '--heads', 'origin', ref])!
	return reply.fields()[0] or { '' }
}

fn plan_proposal(repo string, branch string) !Proposal {
	ref := 'refs/heads/' + branch
	git(repo, ['check-ref-format', ref])!
	expected := remote_head(repo, ref)!
	desired_tree := git(repo, ['write-tree'])!
	if expected != '' {
		git(repo, ['fetch', '--no-tags', 'origin', ref])!
		if git(repo, ['rev-parse', 'FETCH_HEAD'])! != expected {
			return error('Proposal moved during comparison; retry later')
		}
		if git(repo, ['rev-parse', expected + '^{tree}'])! == desired_tree {
			println('Generated files already match the existing proposal; no commit or push.')
			return Proposal{}
		}
	}
	if git(repo, ['rev-parse', 'HEAD^{tree}'])! == desired_tree {
		println('Generated files already match the default branch; no commit or push.')
		return Proposal{}
	}
	return Proposal{
		ref:      ref
		expected: expected
		needed:   true
	}
}

fn apply_proposal(repo string, proposal Proposal, message string) !bool {
	if !proposal.needed {
		return false
	}
	git(repo, ['-c', 'user.name=' + bot_name, '-c', 'user.email=' + bot_email, 'commit', '-m',
		message])!
	// Even creation requires a lease: an empty expected revision means absent.
	git(repo, ['push', '--force-with-lease=${proposal.ref}:${proposal.expected}', 'origin',
		'HEAD:' + proposal.ref])!
	return true
}

fn publish(repo string, branch string, message string) !bool {
	return apply_proposal(repo, plan_proposal(repo, branch)!, message)
}

fn write_output(path string, pushed bool) ! {
	if path != '' {
		mut stream := os.open_append(path)!
		defer { stream.close() }
		stream.writeln('pushed=${pushed}')!
	}
}

fn stage(repo string, text string) ! {
	os.write_file(os.join_path(repo, 'generated.txt'), text)!
	git(repo, ['add', '--', 'generated.txt'])!
}

fn expect_rejected_lease(repo string, proposal Proposal, message string) ! {
	apply_proposal(repo, proposal, message) or {
		if err.msg().contains('stale info') {
			return
		}
		return err
	}
	return error('Concurrent remote branch update was overwritten')
}

fn self_test() ! {
	directory := os.join_path(os.temp_dir(), 'proposal fixture ' + rand.uuid_v4())
	os.mkdir(directory)!
	defer { os.rmdir_all(directory) or {} }
	remote := os.join_path(directory, 'remote.git')
	repo := os.join_path(directory, 'work')
	os.mkdir(repo)!
	git(directory, ['init', '--bare', remote])!
	git(repo, ['init', '--initial-branch=master'])!
	git(repo, ['config', 'user.name', 'Fixture'])!
	git(repo, ['config', 'user.email', 'fixture@example.invalid'])!
	git(repo, ['config', 'commit.gpgsign', 'false'])!
	stage(repo, 'old bindings\n')!
	git(repo, ['commit', '-m', 'base'])!
	git(repo, ['remote', 'add', 'origin', remote])!
	git(repo, ['push', 'origin', 'master'])!
	base := git(repo, ['rev-parse', 'HEAD'])!
	branch := 'automation/generated-update'
	ref := 'refs/heads/' + branch
	message := "Regenerate the project's bindings"
	assert !publish(repo, branch, message)!
	assert remote_head(repo, ref)! == ''

	stage(repo, 'new bindings\n')!
	assert publish(repo, branch, message)!
	first := remote_head(repo, ref)!
	assert first != '' && first != base
	assert git(repo, ['log', '-1', '--format=%s'])! == message
	// All branch switches and remote updates are confined to the fixture.
	git(repo, ['checkout', '--detach', base])!
	stage(repo, 'new bindings\n')!
	assert !publish(repo, branch, message)!
	assert git(repo, ['rev-parse', 'HEAD'])! == base
	assert remote_head(repo, ref)! == first
	stage(repo, 'changed bindings\n')!
	assert publish(repo, branch, message)!
	second := remote_head(repo, ref)!
	assert second != '' && second != first

	git(repo, ['checkout', '--detach', base])!
	os.write_file(os.join_path(repo, 'loader.v'), 'updated loader\n')!
	git(repo, ['add', '--', 'loader.v'])!
	git(repo, ['commit', '-m', 'base update'])!
	stage(repo, 'changed bindings\n')!
	assert publish(repo, branch, message)!
	third := remote_head(repo, ref)!
	assert third != second
	assert git(repo, ['show', 'HEAD:loader.v'])! == 'updated loader'

	stage(repo, 'racing bindings\n')!
	plan := plan_proposal(repo, branch)!
	assert plan.expected == third
	git(remote, ['update-ref', ref, base, third])!
	expect_rejected_lease(repo, plan, message)!
	assert remote_head(repo, ref)! == base

	stage(repo, 'racing creation\n')!
	new_branch := 'automation/new-branch'
	new_ref := 'refs/heads/' + new_branch
	first_plan := plan_proposal(repo, new_branch)!
	assert first_plan.needed && first_plan.expected == ''
	git(remote, ['update-ref', new_ref, base])!
	expect_rejected_lease(repo, first_plan, message)!
	assert remote_head(repo, new_ref)! == base

	output := os.join_path(directory, 'actions-output')
	write_output(output, true)!
	write_output(output, false)!
	assert os.read_file(output)! == 'pushed=true\npushed=false\n'
	println('Publisher creation, no-op, update, and lease fixtures passed.')
}

fn run_cli() ! {
	mut parser := flag.new_flag_parser(os.args[1..])
	parser.application('publish_generated_branch')
	parser.description('Publish a staged Git tree using a lease on the proposal branch.')
	test := parser.bool('self-test', 0, false, 'run against temporary local Git repositories')
	if parser.bool('help', `h`, false, 'show help') {
		println(parser.usage())
		return
	}
	args := parser.finalize()!
	if test && args.len == 0 {
		self_test()!
		return
	}
	if test || args.len != 2 {
		return error('expected a proposal branch and a commit message. See --help.')
	}
	pushed := publish(os.getwd(), args[0], args[1])!
	write_output(os.getenv('GITHUB_OUTPUT'), pushed)!
}

run_cli() or {
	eprintln(err)
	exit(1)
}
