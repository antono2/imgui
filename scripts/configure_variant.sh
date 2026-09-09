#!/usr/bin/env bash
set -euo pipefail

variant=${1:-}
[[ $variant == standard || $variant == docking ]] || {
	echo 'Usage: configure_variant.sh standard|docking' >&2
	exit 2
}

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)
binding="$repo_dir/impl_vulkan/imgui_impl_vulkan.c.v"

# Start from the standard layout. The official docking backend adds one field
# to PipelineInfo and one field to InitInfo; either changes all following C ABI
# offsets, so compiling one layout against the other is unsafe.
perl -0pi -e 's/\n\t\/\/ VIMGUI_DOCKING_PIPELINE_BEGIN\n.*?\n\t\/\/ VIMGUI_DOCKING_PIPELINE_END//s; s/\n\t\/\/ VIMGUI_DOCKING_INIT_BEGIN\n.*?\n\t\/\/ VIMGUI_DOCKING_INIT_END//s' "$binding"

if [[ $variant == docking ]]; then
	perl -0pi -e 's/(\tpipeline_rendering_create_info vk\.PipelineRenderingCreateInfoKHR\n)/$1\t\/\/ VIMGUI_DOCKING_PIPELINE_BEGIN\n\tswap_chain_image_usage         vk.ImageUsageFlags\n\t\/\/ VIMGUI_DOCKING_PIPELINE_END\n/ or die "PipelineInfo anchor not found\n"; s/(\tpipeline_info_main             PipelineInfo\n)/$1\t\/\/ VIMGUI_DOCKING_INIT_BEGIN\n\tpipeline_info_for_viewports    PipelineInfo\n\t\/\/ VIMGUI_DOCKING_INIT_END\n/ or die "InitInfo anchor not found\n"' "$binding"
fi

v fmt -w "$binding"
