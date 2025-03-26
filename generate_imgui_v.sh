#!/bin/bash

# Make sure the current working dir = this script dir
GENERATE_IMGUI_V_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $GENERATE_IMGUI_V_SCRIPT_DIR
printf " --- Changed working dir to\n$GENERATE_IMGUI_V_SCRIPT_DIR\n\n"
# Pull imgui and dear_bindings
git submodule foreach git pull

printf " --- Copy imconfig.h if not there\n\n"
if [ ! -f include/imconfig.h ]; then
  cp imgui/imconfig.h include/
fi


printf " --- Generate dear_bindings dcimgui.h and glfw & vulkan backends\n"
pushd dear_bindings
#sudo apt install -y python3-ply
## Alternatively
#pipx install cookiecutter
#pipx runpip cookiecutter install -r requirements.txt
#pipx run dear_bindings.py -o ../include/dcimgui ../imgui/imgui.h
#pipx run dear_bindings.py -o ../include/dcimgui_internal --include ../imgui/imgui.h ../imgui/imgui_internal.h
#pipx run dear_bindings.py --backend --include ../imgui/imgui.h --imconfig-path ../imgui/imconfig.h -o ../include/backends/dcimgui_impl_vulkan ../imgui/backends/imgui_impl_vulkan.h
#pipx run dear_bindings.py --backend --include ../imgui/imgui.h --imconfig-path ../imgui/imconfig.h -o ../include/backends/dcimgui_impl_glfw ../imgui/backends/imgui_impl_glfw.h
python3 dear_bindings.py -o ../include/dcimgui ../imgui/imgui.h
python3 dear_bindings.py -o ../include/dcimgui_internal --include ../imgui/imgui.h ../imgui/imgui_internal.h
python3 dear_bindings.py --backend --include ../imgui/imgui.h --imconfig-path ../imgui/imconfig.h -o ../include/backends/dcimgui_impl_vulkan ../imgui/backends/imgui_impl_vulkan.h
python3 dear_bindings.py --backend --include ../imgui/imgui.h --imconfig-path ../imgui/imconfig.h -o ../include/backends/dcimgui_impl_glfw ../imgui/backends/imgui_impl_glfw.h
popd

printf " --- Translate C to V\n\n"
v translate include/dcimgui.h &> /dev/null
mv include/dcimgui.v src/imgui.v

printf " --- Cleanup\n\n"
./cleanup_imgui.perl
v fmt -w src/imgui.v &> /dev/null
popd

