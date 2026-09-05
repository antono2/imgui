#!/usr/bin/env bash
# Build the native Dear ImGui/ImPlot library for this machine without
# regenerating the V bindings. This avoids copying a libvimgui built against a
# newer glibc onto an older Linux installation.
set -euo pipefail

linkage=${VIMGUI_LINKAGE:-shared}
glfw_provider=${VIMGUI_GLFW_PROVIDER:-system}
glfw_version=${VIMGUI_GLFW_VERSION:-3.3}

while (($#)); do
	case "$1" in
		--linkage) linkage=$2; shift 2 ;;
		--glfw) glfw_provider=$2; shift 2 ;;
		--glfw-version) glfw_version=$2; shift 2 ;;
		-h|--help)
			echo 'Usage: build_vimgui.sh [--linkage shared|static] [--glfw system|bundled] [--glfw-version VERSION]'
			exit 0 ;;
		*) echo "Unknown option: $1" >&2; exit 2 ;;
	esac
done

if [[ $linkage != shared && $linkage != static ]]; then
	echo 'linkage must be shared or static' >&2
	exit 2
fi
if [[ $glfw_provider != system && $glfw_provider != bundled ]]; then
	echo 'glfw provider must be system or bundled' >&2
	exit 2
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

if [[ ! -f "$SCRIPT_DIR/CMakeLists.txt" || ! -f "$SCRIPT_DIR/cimgui/cimgui.cpp" || ! -f "$SCRIPT_DIR/cimplot/cimplot.cpp" ]]; then
	echo 'Missing cimgui or cimplot sources. Run generate_v.sh first (or initialise the submodules).'
	exit 1
fi

static_build=OFF
library_suffix=so
if [[ $linkage == static ]]; then
	static_build=ON
	library_suffix=a
fi
build_dir="$SCRIPT_DIR/build/${linkage}-${glfw_provider}-${glfw_version}"

cmake -S "$SCRIPT_DIR" -B "$build_dir" \
	-DVIMGUI_OUTPUT_DIR="$SCRIPT_DIR/lib" \
	-DSTATIC_BUILD="$static_build" \
	-DVIMGUI_GLFW_PROVIDER="$glfw_provider" \
	-DVIMGUI_GLFW_VERSION="$glfw_version" \
	-DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}" \
	-DCIMGUI_NO_EXPORT=ON
cmake --build "$build_dir" --parallel

echo "Built $SCRIPT_DIR/lib/libvimgui.$library_suffix (GLFW: $glfw_provider${glfw_provider:+, version $glfw_version})"
