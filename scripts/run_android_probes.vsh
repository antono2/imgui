// Build and run Android device capability and offscreen Vulkan probes.
import os
import tooling

tooling.android_probes(os.real_path(os.dir(@DIR)), os.args[1..]) or {
	eprintln(err)
	exit(if err.code() == 2 { 2 } else { 1 })
}
