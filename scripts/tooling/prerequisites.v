// Discovers build prerequisites and reports platform-specific setup requirements.
module tooling

import os

pub fn setup_vulkan(root string, mode string) ! {
	mut module_root := os.join_path(os.dir(root), 'vulkan')
	if !os.is_file(os.join_path(module_root, 'v.mod')) {
		module_root = os.join_path(os.vmodules_dir(), 'antono2', 'vulkan')
	}
	script := os.join_path(module_root, 'setup.vsh')
	if !os.is_file(script) {
		return error('antono2.vulkan does not include setup.vsh; install or update it first')
	}
	tooling.command(tooling.compiler(), ['run', script, mode])!
	$if windows {
		if os.getenv('VULKAN_SDK') == '' {
			value := tooling.output('powershell', ['-NoProfile', '-Command',
				"[Environment]::GetEnvironmentVariable('VULKAN_SDK', 'Machine')"])!
			if value != '' { os.setenv('VULKAN_SDK', value, true) }
		}
	}
}

pub fn system_glfw() ! {
	$if linux {
		for key, value in {
			'VULKAN_SDK':   '/usr'
			'GLFW_INCLUDE': '/usr/include'
			'GLFW_LIB':     '/usr/lib/x86_64-linux-gnu'
		} {
			if os.getenv(key) == '' { os.setenv(key, value, true) }
		}
	} $else $if macos {
		if os.getenv('GLFW_INCLUDE') == '' || os.getenv('GLFW_LIB') == '' {
			prefix := output('brew', ['--prefix', 'glfw'])!
			if os.getenv('GLFW_INCLUDE') == '' {
				os.setenv('GLFW_INCLUDE', os.join_path(prefix, 'include'), true)
			}
			if os.getenv('GLFW_LIB') == '' { os.setenv('GLFW_LIB', os.join_path(prefix, 'lib'), true) }
		}
	}
}

pub fn install_system_dependencies() ! {
	$if linux {
		mut release := map[string]string{}
		for line in os.read_lines('/etc/os-release')! {
			if line.contains('=') {
				release[line.all_before('=')] = line.all_after('=').trim('"\'')
			}
		}
		if release['ID'] !in ['ubuntu', 'debian'] && 'debian' !in release['ID_LIKE'].split(' ') {
			return error('Automatic installation supports Debian and Ubuntu only; see QUICKSTART.md.')
		}
		command('sudo', ['apt-get', 'update'])!
		command('sudo', ['apt-get', 'install', '-y', 'build-essential', 'cmake', 'git', 'libglfw3-dev',
			'libvulkan-dev', 'libvulkan-volk-dev', 'pkg-config', 'vulkan-tools'])!
	} $else $if macos {
		command('brew', ['install', 'cmake', 'glfw'])!
	} $else $if windows {
		// Visual Studio developer-shell setup belongs to the user's environment.
	} $else {
		return error('Automatic setup is unsupported on this operating system.')
	}
}

pub fn check_prerequisites(bundled_glfw bool) ! {
	mut missing := []string{}
	mut commands := ['git', 'cmake']
	$if windows {
		commands << 'cl'
	} $else {
		commands << ['cc', 'c++']
	}
	$if linux {
		commands << 'pkg-config'
	}
	for name in commands {
		if os.exists_in_system_path(name) { println('[ok]      ${name}') } else { missing << name }
	}
	println('[ok]      V compiler: ${compiler()}')
	$if linux {
		if os.exists_in_system_path('pkg-config') {
			mut packages := ['vulkan']
			if !bundled_glfw { packages << 'glfw3' }
			for name in packages {
				output('pkg-config', ['--exists', name]) or {
					missing << 'pkg-config ${name}'
					continue
				}
				println('[ok]      pkg-config ${name}')
			}
		}
		root := if os.getenv('VULKAN_SDK') == '' { '/usr' } else { os.getenv('VULKAN_SDK') }
		mut volk_found := false
		for header in [os.join_path(root, 'include', 'volk.h'),
			os.join_path(root, 'include', 'volk', 'volk.h'), '/usr/include/volk.h',
			'/usr/include/volk/volk.h'] {
			if os.is_file(header) {
				println('[ok]      Volk header: ${header}')
				volk_found = true
				break
			}
		}
		if !volk_found { missing << 'Volk header (libvulkan-volk-dev or a Vulkan SDK containing Volk)' }
	} $else {
		sdk := os.getenv('VULKAN_SDK')
		if sdk == '' || (!os.is_file(os.join_path(sdk, 'include', 'vulkan', 'vulkan.h')) && !os.is_file(os.join_path(sdk, 'Include', 'vulkan', 'vulkan.h'))) {
			missing << 'Vulkan headers under VULKAN_SDK'
		} else {
			println('[ok]      VULKAN_SDK=${sdk}')
		}
		if !bundled_glfw {
			for key in ['GLFW_INCLUDE', 'GLFW_LIB'] {
				if os.getenv(key) == '' { missing << key } else { println('[ok]      ${key}=${os.getenv(key)}') }
			}
		}
	}
	if bundled_glfw { println('[ok]      GLFW will be downloaded by CMake') }
	if os.exists_in_system_path('vulkaninfo') {
		println('[ok]      vulkaninfo')
	} else {
		println('[optional] vulkaninfo (runtime diagnostics)')
	}
	for name in missing {
		eprintln('[missing] ${name}')
	}
	if missing.len > 0 {
		return error('One or more requirements are unavailable. See QUICKSTART.md.')
	}
	println('Dear ImGui build prerequisites look usable.')
}
