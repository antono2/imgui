#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
	'') ;;
	-h|--help)
		echo 'Usage: run_demo.sh'
		echo 'Build libvimgui and launch the pinned GLFW/Vulkan visual demo from source.'
		echo 'This may require about 11 GiB of memory; prefer a prebuilt release when available.'
		exit 0
		;;
	*) echo "Unknown option: $1" >&2; exit 2 ;;
esac

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
repo_dir=$(cd -- "$script_dir/.." >/dev/null 2>&1 && pwd)
repo_parent=$(dirname -- "$repo_dir")
demo_revision=051c462792feab4d0963e8715188b8b0e7695b3e
demo_dir="$repo_dir/build/v_imgui_examples"

for command_name in git cmake v; do
	command -v "$command_name" >/dev/null 2>&1 || {
		echo "Missing required command: $command_name. Run scripts/setup_linux.sh --check." >&2
		exit 1
	}
done

if [[ -d "$repo_dir/.git" ]]; then
	git -C "$repo_dir" submodule update --init --recursive
fi
"$repo_dir/build_vimgui.sh" --linkage shared --glfw system

if [[ ! -d "$demo_dir/.git" ]]; then
	git clone https://github.com/antono2/v_imgui_examples.git "$demo_dir"
fi
git -C "$demo_dir" fetch --quiet origin "$demo_revision"
git -C "$demo_dir" checkout --quiet --detach "$demo_revision"

export VULKAN_SDK=${VULKAN_SDK:-/usr}
export GLFW_INCLUDE=${GLFW_INCLUDE:-/usr/include}
export GLFW_LIB=${GLFW_LIB:-/usr/lib/x86_64-linux-gnu}

exec v -no-memory-limit -path "$repo_parent|@vlib|@vmodules" run "$demo_dir"
