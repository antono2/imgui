// Build and verify the Android packages and link probes used by CI.
import os
import tooling

tooling.android_ci(os.dir(@DIR), os.args[1..]) or {
	eprintln(err.msg())
	exit(if err.code() > 0 { err.code() } else { 1 })
}
