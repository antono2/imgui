// Update upstream gitlinks after validating both fast-forwards, then regenerate bindings.
import os

const usage = 'Usage: v run scripts/update_upstream.vsh standard|docking [--check-only] [--regenerate-c] [--worktree PATH]'

struct Upstream {
	name   string
	branch string
	head   string
}

fn git_result(module_path string, args []string) os.Result {
	mut command := ['git', '-C', module_path]
	command << args
	return os.exec(command)
}

fn git(module_path string, args ...string) !string {
	result := git_result(module_path, args)
	if result.exit_code != 0 {
		return error('${module_path}: git ${args.join(' ')} failed (exit ${result.exit_code})\n${result.output}')
	}
	return result.output
}

fn upstream(name string, branch string) !Upstream {
	if git(name, 'status', '--porcelain')!.trim_space() != '' {
		return error('${name} has local changes. Preserve them before updating upstream.')
	}
	ref := 'refs/heads/' + branch
	response := git(name, 'ls-remote', '--heads', 'origin', ref)!.fields()
	if response.len != 2 || response[1] != ref || response[0].len != 40
		|| !response[0].bytes().all(it.is_hex_digit()) {
		return error('Could not resolve ${name} origin/${branch} to one commit.')
	}
	return Upstream{name, branch, response[0]}
}

fn (dependency Upstream) validate_fetch() ! {
	mut options := ['fetch']
	// A shallow submodule history cannot establish ancestry.
	if git(dependency.name, 'rev-parse', '--is-shallow-repository')!.trim_space() == 'true' {
		options << '--unshallow'
	}
	options << ['origin', dependency.branch]
	print(git(dependency.name, ...options)!)
	if git(dependency.name, 'rev-parse', 'FETCH_HEAD')!.trim_space() != dependency.head {
		return error('${dependency.name} origin/${dependency.branch} moved during update. Retry later.')
	}
	result := git_result(dependency.name, ['merge-base', '--is-ancestor', 'HEAD', dependency.head])
	if result.exit_code != 0 {
		return error('${dependency.name} origin/${dependency.branch} is not a fast-forward update.\n${result.output}')
	}
}

fn run_script(path string, args []string) ! {
	mut command := [@VEXE, 'run', path]
	command << args
	result := os.exec(command)
	print(result.output)
	if result.exit_code != 0 {
		return error('${path} failed with status ${result.exit_code}')
	}
}

fn update(root string, variant string, check_only bool, regenerate_c bool) ! {
	os.chdir(root)!
	cimgui_branch := if variant == 'standard' { 'master' } else { 'docking_inter' }
	modules := [upstream('cimgui', cimgui_branch)!, upstream('cimplot', 'master')!]
	mut changed := false
	for dependency in modules {
		if git(dependency.name, 'rev-parse', 'HEAD')!.trim_space() != dependency.head {
			changed = true
		}
	}
	println('changed=${changed}')
	if check_only {
		return
	}
	if !os.is_file('generate.vsh') || !os.is_file('scripts/configure_variant.vsh') {
		return error('Expected generator and variant configuration in ${root}')
	}
	// Prove both ancestry checks before touching either working tree.
	for dependency in modules {
		dependency.validate_fetch()!
	}
	for dependency in modules {
		print(git(dependency.name, 'switch', '--detach', dependency.head)!)
		print(git(dependency.name, 'submodule', 'update', '--init', '--recursive')!)
	}
	os.write_file('UPSTREAM_VARIANT', variant + '\n')!
	run_script('scripts/configure_variant.vsh', [variant])!
	run_script('generate.vsh', if regenerate_c { ['--regenerate-c'] } else { []string{} })!
	cimgui := git('cimgui', 'rev-parse', '--short', 'HEAD')!.trim_space()
	cimplot := git('cimplot', 'rev-parse', '--short', 'HEAD')!.trim_space()
	println('Updated ${variant} bindings: cimgui=${cimgui} cimplot=${cimplot}')
}

fn main() {
	args := os.args[1..]
	if args.any(it in ['--help', '-h']) {
		println(usage)
		return
	}
	if args.len == 0 || args[0] !in ['standard', 'docking'] {
		eprintln(usage)
		exit(2)
	}
	mut root := os.dir(@DIR)
	mut check_only := false
	mut regenerate_c := false
	mut index := 1
	for index < args.len {
		match args[index] {
			'--check-only' { check_only = true }
			'--regenerate-c' { regenerate_c = true }
			'--worktree' {
				index++
				if index >= args.len {
					eprintln(usage)
					exit(2)
				}
				root = os.abs_path(args[index])
			}
			else {
				eprintln('Unknown option: ${args[index]}')
				eprintln(usage)
				exit(2)
			}
		}
		index++
	}
	update(root, args[0], check_only, regenerate_c) or {
		eprintln(err)
		exit(1)
	}
}
