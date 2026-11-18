// Sign, install and run the sample's iOS Simulator frame checks.
import os
import tooling

tooling.ios_simulator_smoke(os.args[1..]) or {
	eprintln(err)
	exit(if err.code() == 2 { 2 } else { 1 })
}
