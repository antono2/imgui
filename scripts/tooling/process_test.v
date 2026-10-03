module tooling

import os

fn test_process_preserves_arguments() {
	args := ['two words', '|@vlib|@vmodules', '\$(must remain literal)', 'Unicode: 世界']
	fixture := os.join_path(@DIR, 'fixtures', 'print_args.v')
	mut command_args := ['run', fixture]
	command_args << args
	result := output(compiler(), command_args) or { panic(err) }
	assert result == args.join('\n')
}

fn test_process_reports_failure() {
	output(compiler(), ['run', os.join_path(@DIR, 'fixtures', 'print_args.v'), '--fail']) or {
		assert err.msg().contains('exit code 23')
		return
	}
	assert false, 'Failed child process was reported as successful'
}
