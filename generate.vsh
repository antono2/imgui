#!/usr/bin/env -S v

// Compatibility entry point for the canonical Bash generator. Keeping the
// generation logic in one implementation prevents the two paths from
// producing subtly different bindings.
import os

fn main() {
	mut parts := [os.quoted_path(os.join_path(@DIR, 'generate_v.sh'))]
	for arg in os.args[1..] {
		parts << os.quoted_path(arg)
	}
	result := os.execute(parts.join(' '))
	print(result.output)
	exit(result.exit_code)
}
