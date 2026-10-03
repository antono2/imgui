module main

import os

fn main() {
	if os.args[1..] == ['--fail'] { exit(23) }
	println(os.args[1..].join('\n'))
}
