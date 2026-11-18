// Run the Android accessibility instrumentation on the selected device.
import os
import tooling

tooling.android_accessibility_test(os.real_path(os.dir(@DIR)), os.args[1..]) or {
	eprintln(err)
	exit(if err.code() == 2 { 2 } else { 1 })
}
