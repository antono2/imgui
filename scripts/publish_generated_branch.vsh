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
	mut command := ['git', '-C', repo]
	command << args
	result := os.exec(command)
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
			return Proposal{ ref: ref, expected: expected }
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

type GitHubCommand = fn ([]string) !string

fn github(args []string) !string {
	mut command := ['gh']
	command << args
	result := os.exec(command)
	if result.exit_code != 0 {
		return error('gh ${args.join(' ')} failed: ${result.output.trim_space()}')
	}
	return result.output.trim_space()
}

fn open_request(gh GitHubCommand, base string, branch string) !string {
	return gh(['pr', 'list', '--base', base, '--head', branch, '--state', 'open', '--json', 'number',
		'--jq', '.[0].number // empty'])
}

fn propose_staged(repo string, variant string, base string, dispatch bool, gh GitHubCommand) ! {
	if git(repo, ['rev-parse', 'HEAD^{tree}'])! == git(repo, ['write-tree'])! {
		println('No generated changes to propose.')
		return
	}
	branch := 'generated/upstream-' + variant
	message := 'Update ${variant} ImGui and ImPlot bindings'
	proposal := plan_proposal(repo, branch)!
	if proposal.needed && proposal.expected != '' && open_request(gh, base, branch)! == '' {
		return error('Refusing to replace ${proposal.ref} without an open update PR.')
	}

	pushed := apply_proposal(repo, proposal, message)!
	mut created := false
	if open_request(gh, base, branch)! == '' {
		// Bind creation and recovery to the same proposal we compared or pushed.
		expected := if pushed { git(repo, ['rev-parse', 'HEAD'])! } else { proposal.expected }
		if expected == '' || remote_head(repo, proposal.ref)! != expected {
			return error('Proposal moved before opening the draft. Retry later.')
		}
		cimgui := git(os.join_path(repo, 'cimgui'), ['rev-parse', 'HEAD'])!
		cimplot := git(os.join_path(repo, 'cimplot'), ['rev-parse', 'HEAD'])!
		body := 'Automated upstream refresh for the ${variant} variant. cimgui: ${cimgui}; cimplot: ${cimplot}. Generated V bindings and native sources must pass CI and receive human review before merge.'
		println(gh(['pr', 'create', '--draft', '--base', base, '--head', branch, '--title', message,
			'--body', body])!)
		created = true
	}
	// Personal-token pushes already trigger PR checks. Dispatch explicitly only
	// when the repository token created or updated the proposal.
	if dispatch && (pushed || created) {
		for workflow in ['demo-release.yml', 'mobile-native.yml', 'application-accessibility.yml',
			'portable-tooling.yml'] {
			gh(['workflow', 'run', workflow, '--ref', branch])!
		}
		gh(['workflow', 'run', 'update-upstream.yml', '--ref', branch, '-f', 'validate_only=true'])!
	}
}

fn propose_workflow(repo string, variant string, base string, dispatch bool) ! {
	if (variant == 'docking' && base != 'master') || (variant == 'standard' && base != 'standard')
		|| variant !in ['docking', 'standard'] {
		return error('Expected docking/master or standard/standard for publication.')
	}
	git(repo, ['add', '-A', '--', 'cimgui', 'cimplot', 'UPSTREAM_VARIANT', 'VERSION', 'imgui.v',
		'implot/implot.v', 'include', 'impl_vulkan/imgui_impl_vulkan.c.v'])!
	git(repo, ['diff', '--exit-code'])!
	propose_staged(repo, variant, base, dispatch, github)!
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

fn test_workflow(repo string, remote string, base string, directory string) ! {
	request := os.join_path(directory, 'open-request')
	events := os.join_path(directory, 'workflow-events')
	os.write_file(events, '')!
	gh := fn [request, events] (args []string) !string {
		if args[..2] == ['pr', 'list'] {
			assert args[2..8] == ['--base', 'master', '--head', 'generated/upstream-docking', '--state',
				'open']
			return os.read_file(request) or { '' }
		}
		mut event_log := os.open_append(events)!
		defer { event_log.close() }
		match args[..2] {
			['pr', 'create'] {
				assert args[2..7] == ['--draft', '--base', 'master', '--head',
					'generated/upstream-docking']
				assert args.last().contains('cimgui: ') && args.last().contains('cimplot: ')
				os.write_file(request, '123')!
				event_log.writeln('draft')!
				return 'fixture draft'
			}
			['workflow', 'run'] {
				assert args[3..5] == ['--ref', 'generated/upstream-docking']
				if args[2] == 'update-upstream.yml' {
					assert args[5..] == ['-f', 'validate_only=true']
				}
				event_log.writeln(args[2])!
				return ''
			}
			else {
				return error('Unexpected GitHub command: ${args}')
			}
		}
	}
	for module_dir in ['cimgui', 'cimplot'] {
		path := os.join_path(repo, module_dir)
		os.mkdir(path)!
		git(path, ['init'])!
		git(path, ['-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', '-c',
			'commit.gpgsign=false', 'commit', '--allow-empty', '-m', module_dir])!
	}
	git(repo, ['checkout', '--detach', base])!
	ref := 'refs/heads/generated/upstream-docking'
	propose_staged(repo, 'docking', 'master', true, gh)!
	assert remote_head(repo, ref)! == ''
	assert os.read_file(events)! == ''

	stage(repo, 'workflow proposal\n')!
	propose_staged(repo, 'docking', 'master', true, gh)!
	first := remote_head(repo, ref)!
	assert first != '' && first != base
	expected := ['draft', 'demo-release.yml', 'mobile-native.yml', 'application-accessibility.yml',
		'portable-tooling.yml', 'update-upstream.yml']
	assert os.read_lines(events)! == expected

	git(repo, ['checkout', '--detach', base])!
	stage(repo, 'workflow proposal\n')!
	propose_staged(repo, 'docking', 'master', true, gh)!
	assert remote_head(repo, ref)! == first
	assert os.read_lines(events)! == expected

	// Recover a missing draft from the same branch without changing its commit.
	os.rm(request)!
	propose_staged(repo, 'docking', 'master', true, gh)!
	assert remote_head(repo, ref)! == first
	mut twice := expected.clone()
	twice << expected
	assert os.read_lines(events)! == twice

	// Refuse to replace a different tree without an open request.
	os.rm(request)!
	stage(repo, 'different workflow proposal\n')!
	mut refused := false
	propose_staged(repo, 'docking', 'master', true, gh) or {
		assert err.msg().contains('without an open update PR')
		refused = true
	}
	assert refused
	assert git(remote, ['rev-parse', ref])! == first
	assert os.read_lines(events)! == twice

	// A personal-token update relies on GitHub's normal PR triggers.
	os.write_file(request, '123')!
	propose_staged(repo, 'docking', 'master', false, gh)!
	assert remote_head(repo, ref)! != first
	assert os.read_lines(events)! == twice
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
	test_workflow(repo, remote, base, directory)!
	println('Publisher and draft creation, no-op, recovery, dispatch, and lease fixtures passed.')
}

fn run_cli() ! {
	mut parser := flag.new_flag_parser(os.args[1..])
	parser.application('publish_generated_branch')
	parser.description('Publish a staged Git tree using a lease on the proposal branch.')
	propose := parser.bool('propose', 0, false, 'stage and propose upstream bindings in GitHub Actions')
	test := parser.bool('self-test', 0, false, 'run against temporary local Git repositories')
	if parser.bool('help', `h`, false, 'show help') {
		println(parser.usage())
		return
	}
	args := parser.finalize()!
	if test && !propose && args.len == 0 {
		self_test()!
		return
	}
	if propose && !test && args.len == 2 {
		propose_workflow(os.getwd(), args[0], args[1], os.getenv('DISPATCH_CI') == 'true')!
		return
	}
	if test || propose || args.len != 2 {
		return error('expected a proposal branch and a commit message. See --help.')
	}
	pushed := publish(os.getwd(), args[0], args[1])!
	write_output(os.getenv('GITHUB_OUTPUT'), pushed)!
}

run_cli() or {
	eprintln(err)
	exit(1)
}
