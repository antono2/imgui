#!/usr/bin/env bash
set -euo pipefail

usage() {
	printf '%s\n' 'Usage: setup_linux.sh [--check|--install]' '' \
		'  --check    Report prerequisites without changing the system (default).' \
		'  --install  Install Debian/Ubuntu prerequisites and V module dependencies.'
}

mode=check
case "${1:-}" in
	''|--check) ;;
	--install) mode=install ;;
	-h|--help) usage; exit 0 ;;
	*) usage >&2; exit 2 ;;
esac

if [[ $mode == install ]]; then
	if [[ ! -r /etc/os-release ]]; then
		echo 'Cannot identify this Linux distribution.' >&2
		exit 1
	fi
	# shellcheck disable=SC1091
	source /etc/os-release
	case "${ID:-}:${ID_LIKE:-}" in
		ubuntu:*|debian:*|*:debian*) ;;
		*) echo 'Automatic installation supports Debian and Ubuntu only; see QUICKSTART.md.' >&2; exit 1 ;;
	esac
	packages=(build-essential cmake git libglfw3-dev libvulkan-dev libvulkan-volk-dev pkg-config vulkan-tools)
	printf 'Installing: %s\n' "${packages[*]}"
	sudo apt-get update
	sudo apt-get install -y "${packages[@]}"
fi

missing=0
for command_name in git cmake cc c++ pkg-config; do
	if command -v "$command_name" >/dev/null 2>&1; then
		printf '[ok]      %s\n' "$command_name"
	else
		printf '[missing] %s\n' "$command_name"
		missing=1
	fi
done

if command -v vulkaninfo >/dev/null 2>&1; then
	echo '[ok]      vulkaninfo'
else
	echo '[optional] vulkaninfo (needed to diagnose demo/runtime availability)'
fi

if command -v v >/dev/null 2>&1; then
	printf '[ok]      v: %s\n' "$(v version 2>/dev/null || true)"
	if [[ $mode == install ]]; then
		v install https://github.com/antono2/vulkan
		v install https://github.com/antono2/glfw
	fi
else
	echo '[missing] v (install from https://github.com/vlang/v)'
	missing=1
fi

if command -v pkg-config >/dev/null 2>&1; then
	for package_name in glfw3 vulkan; do
		if pkg-config --exists "$package_name"; then
			printf '[ok]      pkg-config %s\n' "$package_name"
		else
			printf '[missing] pkg-config %s\n' "$package_name"
			missing=1
		fi
	done
fi

if command -v vulkaninfo >/dev/null 2>&1; then
	vulkan_summary=$(mktemp)
	trap 'rm -f "$vulkan_summary"' EXIT
	if vulkaninfo --summary >"$vulkan_summary" 2>&1; then
		echo '[ok]      Vulkan loader can enumerate devices'
	else
		echo '[warning] vulkaninfo could not enumerate a usable Vulkan device; building may work, but the demo may not run'
	fi
fi

if ((missing)); then
	echo 'One or more requirements are unavailable. See QUICKSTART.md.' >&2
	exit 1
fi
echo 'Dear ImGui build prerequisites look usable.'
