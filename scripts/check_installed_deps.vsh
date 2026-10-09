#!/usr/bin/env -S v run

// Verify direct and transitive release pins against the installed Git checkouts.
// Companion tags require an explicit --tag-suffix module=suffix argument.
import os
import v.vmod

fn check_module(root string, modules string, suffixes map[string]string, mut checked map[string]string) ! {
	manifest := vmod.from_file(os.join_path(root, 'v.mod'))!
	for dependency in manifest.dependencies {
		name, declared_tag := dependency.rsplit_once('@') or {
			return error('Dependency is not pinned in ${root}: ${dependency}')
		}
		tag := declared_tag + suffixes[name]
		if previous := checked[name] {
			if previous != tag {
				return error('Conflicting dependency pins for ${name}: ${previous} and ${tag}')
			}
			continue
		}
		module_dir := os.join_path(modules, ...name.split('.'))
		actual := os.execute('git -C ${os.quoted_path(module_dir)} rev-parse HEAD')
		expected := os.execute('git -C ${os.quoted_path(module_dir)} rev-parse ${os.quoted_path(
			'refs/tags/' + tag + '^{commit}')}')
		if actual.exit_code != 0 || expected.exit_code != 0 {
			return error('Cannot verify installed ${name}@${tag}: ${actual.output}${expected.output}')
		}
		if actual.output.trim_space() != expected.output.trim_space() {
			return error('Installed ${name} does not match ${tag}: ${actual.output.trim_space()}')
		}
		checked[name] = tag
		println('Verified ${name}@${tag}')
		check_module(module_dir, modules, suffixes, mut checked)!
	}
}

fn check_dependencies() ! {
	mut suffixes := map[string]string{}
	mut index := 1
	for index < os.args.len {
		if os.args[index] != '--tag-suffix' || index + 1 >= os.args.len {
			return error('Usage: v run scripts/check_installed_deps.vsh [--tag-suffix module=suffix]')
		}
		name, suffix := os.args[index + 1].split_once('=') or {
			return error('--tag-suffix requires module=suffix')
		}
		if name == '' || suffix == '' || name in suffixes {
			return error('Invalid or repeated tag suffix: ${os.args[index + 1]}')
		}
		suffixes[name] = suffix
		index += 2
	}
	root := os.dir(os.dir(os.real_path(@FILE)))
	configured := os.getenv('VMODULES')
	modules := if configured != '' { configured } else { os.join_path(os.home_dir(), '.vmodules') }
	mut checked := map[string]string{}
	check_module(root, modules, suffixes, mut checked)!
	for name, _ in suffixes {
		if name !in checked {
			return error('Tag suffix did not match a dependency: ${name}')
		}
	}
}

fn main() {
	check_dependencies() or {
		eprintln(err)
		exit(1)
	}
}
