// Installs tagged dependency checkouts without resetting existing work.
module tooling

import os
import rand
import v.vmod

fn verify_pinned_checkout(directory string, tag string) ! {
	if !os.exists(os.join_path(directory, '.git')) {
		return error('Existing directory is not a managed Git checkout: ${directory}')
	}
	head := output('git', ['-C', directory, 'rev-parse', 'HEAD'])!
	expected := output('git', ['-C', directory, 'rev-parse', '--verify', 'refs/tags/${tag}^{commit}'])!
	if head != expected {
		return error('Checkout is not at the tested tag ${tag}: ${directory}')
	}
	if output('git', ['-C', directory, 'status', '--porcelain'])! != '' {
		return error('Preserve local changes in ${directory}, or choose another VMODULES directory.')
	}
}

fn prepare_pinned_checkout(repository string, tag string, directory string) ! {
	if os.exists(directory) || os.is_link(directory) {
		verify_pinned_checkout(directory, tag)!
		return
	}
	os.mkdir_all(os.dir(directory))!
	stage := os.join_path(os.dir(directory), '.module-' + rand.uuid_v4())
	defer { os.rmdir_all(stage) or {} }
	command('git', ['clone', '--filter=blob:none', '--depth', '1', '--branch', tag, '--', repository,
		stage])!
	verify_pinned_checkout(stage, tag)!
	// Publish only the complete checkout. Do not replace a concurrent install.
	os.rename_dir(stage, directory) or {
		if !os.is_dir(directory) {
			return err
		}
		verify_pinned_checkout(directory, tag)!
	}
}

fn prepare_dependencies(root string, modules string, mut checked map[string]string) ! {
	manifest := vmod.from_file(os.join_path(root, 'v.mod'))!
	for dependency in manifest.dependencies {
		name, tag := dependency.rsplit_once('@') or {
			return error('Dependency is not pinned in ${root}: ${dependency}')
		}
		module_name := name.all_after_last('.')
		if name != 'antono2.${module_name}' || module_name == '' || tag == ''
			|| !module_name.bytes().all((it >= `a` && it <= `z`) || (it >= `0` && it <= `9`) || it == `_`) {
			return error('Expected an antono2 module with a release tag: ${dependency}')
		}
		if previous := checked[name] {
			if previous != tag {
				return error('Conflicting dependency pins for ${name}: ${previous} and ${tag}')
			}
			continue
		}
		repository := if module_name == 'vkmemalloc' {
			'vulkan_memory_allocator'
		} else {
			module_name
		}
		directory := os.join_path(modules, 'antono2', module_name)
		prepare_pinned_checkout('https://github.com/antono2/${repository}.git', tag, directory)!
		checked[name] = tag
		prepare_dependencies(directory, modules, mut checked)!
	}
}

// Older VPM versions cannot reliably reuse pinned modules in paths with spaces.
pub fn prepare_pinned_modules(root string, modules string) ! {
	mut checked := map[string]string{}
	prepare_dependencies(root, modules, mut checked)!
}
