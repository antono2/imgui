// Require the exact file entries that a consumer expects to load from a ZIP or APK.
import os
import tooling

fn run(args []string) ! {
	usage := 'Usage: v run scripts/check_zip_files.vsh ARCHIVE MEMBER [MEMBER ...]'
	if args in [['--help'], ['-h']] {
		println(usage)
		return
	}
	if args.len < 2 {
		return error(usage)
	}
	tooling.require_zip_files(args[0], args[1..])!
	println('Verified required entries in ${args[0]}')
}

run(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
