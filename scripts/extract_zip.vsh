#!/usr/bin/env -S v run
// Extracts downloaded tooling archives through the shared archive utility.

import os
import tooling

fn main() {
	if os.args[1..] == ['--help'] || os.args[1..] == ['-h'] {
		println('Usage: ./scripts/extract_zip.vsh archive.zip destination')
		return
	}
	if os.args.len != 3 {
		eprintln('Usage: ./scripts/extract_zip.vsh archive.zip destination')
		exit(2)
	}
	tooling.extract_zip(os.args[1], os.args[2]) or {
		eprintln(err)
		exit(1)
	}
}
