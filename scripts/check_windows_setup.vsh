// Exercise the documented bootstrap and repeat installs in a checkout with spaces.
import os
import tooling

fn run(args []string) ! {
	if args.len != 1 || args[0] == '' {
		return error('Usage: v run scripts/check_windows_setup.vsh COMPILER_CACHE')
	}
	cache := os.abs_path(args[0])
	os.chdir(os.dir(@DIR))!
	powershell := ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File']
	tooling.command('powershell.exe', powershell + ['scripts/test_windows_setup.ps1'])!
	setup := powershell + ['scripts/setup_windows.ps1', '-CacheDirectory', cache]
	tooling.command('powershell.exe', setup + ['-Check'])!
	if os.exists(cache) {
		return error('Read-only check created the compiler cache: ${cache}')
	}
	tooling.command('powershell.exe', setup)!
	tooling.command('powershell.exe', setup)!
	tooling.command('powershell.exe', setup + ['-PrepareOnly'])!
	for name in ['v_imgui_demo.exe', 'vimgui.dll', 'glfw3.dll'] {
		artifact := os.join_path('build', 'windows-demo', name)
		if !os.is_file(artifact) {
			return error('Missing demo artifact: ${artifact}')
		}
	}
	// Keep testing the original entry point as well as its new V implementation.
	tooling.command('powershell.exe', powershell + ['scripts/smoke_windows_demo.ps1'])!
}

run(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
