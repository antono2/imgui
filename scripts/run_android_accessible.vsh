// Build or deploy an Android NativeActivity example.
import os
import tooling

tooling.android_demo(os.real_path(os.dir(@DIR)), true, os.args[1..]) or {
	eprintln(err)
	exit(if err.code() == 2 { 2 } else { 1 })
}
