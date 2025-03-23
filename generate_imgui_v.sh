#!/bin/bash

# Make sure the current working dir = this script dir
GENERATE_IMGUI_V_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $GENERATE_IMGUI_V_SCRIPT_DIR

# Pull imgui and dear_bindings
git submodule foreach git pull

# Generate dear_bindings dcimgui.h and implementations for glfw and vulkan
pushd dear_bindings
sudo apt install -y python3-ply
#pipx install cookiecutter
#pipx runpip cookiecutter install -r requirements.txt
pipx run dear_bindings.py -o ../imgui/dcimgui ../imgui/imgui.h
pipx run dear_bindings.py -o ../imgui/dcimgui --include ../imgui/imgui.h ../imgui/imgui_internal.h
pipx run dear_bindings.py --backend --include ../imgui/imgui.h --imconfig-path ../imgui/imconfig.h -o ../imgui/backends/dcimgui_impl_vulkan ../imgui/backends/imgui_impl_vulkan.h
pipx run dear_bindings.py --backend --include ../imgui/imgui.h --imconfig-path ../imgui/imconfig.h -o ../imgui/backends/dcimgui_impl_glfw ../imgui/backends/imgui_impl_glfw.h
popd

# Translate C to V
v translate imgui/dcimgui.h &> /dev/null
mv imgui/dcimgui.v src/imgui.v &> /dev/null

# Cleanup
./cleanup_imgui.perl
v fmt -w src/imgui.v &> /dev/null
popd

popd # $GENERATE_IMGUI_V_SCRIPT_DIR
