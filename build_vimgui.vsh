#!/usr/bin/env -S v

// V entry point for the build-only helper. The shell implementation carries
// the CMake invocation so it is equally usable on machines without V in PATH.
import os

os.execute_or_exit('${@DIR}/build_vimgui.sh')
