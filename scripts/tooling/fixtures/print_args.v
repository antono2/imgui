// Prints received arguments so process tests can detect quoting and argument-boundary errors.
module main

import os

fn main() {
	if os.args[1..] == ['--fail'] { exit(23) }
	println(os.args[1..].join('\n'))
}
