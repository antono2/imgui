#!/usr/bin/env bash
set -euo pipefail

# Make sure the current working dir = this script dir
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
pushd "$SCRIPT_DIR" >/dev/null
printf " --- Changed working dir to\n$SCRIPT_DIR\n\n"

printf " --- Stashing CIMGUI / CIMPLOT changes"
#pushd cimgui
#git stash
#popd
#pushd cimplot
#git stash
#popd
printf " --- Updating Submodules"
printf "     Note: Change submodule version to change cimgui version"
#git submodule update --init --recursive
#git submodule foreach git pull

TARGETS_CIMGUI="internal" #"comments constructors internal noimstrv"
TARGETS_CIMPLOT="internal"
#DFLAGS="-DCMAKE_BUILD_TYPE=RelWithDebInfo -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=ON -DIMGUI_STATIC=ON -DCIMGUI_NO_EXPORT=ON -DCIMGUI_USE_GLFW=ON"
DFLAGS="-DSTATIC_BUILD=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=ON -DIMGUI_STATIC=OFF -DCIMGUI_NO_EXPORT=ON -DCIMGUI_USE_GLFW=ON"
CFLAGS="glfw" #opengl3 opengl2 sdl2 sdl3"

printf " --- Generate cimgui\n\n"
rm -f cimgui/CMakeCache.txt cimplot/CMakeCache.txt CMakeCache.txt
pushd cimgui/generator
  # ./generator.lua <compiler> "<targets>" <CFLAGS>
  luajit ./generator.lua gcc $TARGETS_CIMGUI $CFLAGS &> /dev/null
popd

printf " --- Build cimgui\n\n"
pushd cimgui
#  cmake $DFLAGS $CFLAGS . &> /dev/null
#  make &> /dev/null
printf " --- Add ____TRANSLATIONFIX____ to cimgui.h\n\n"
# -p=print each line -i=edit in place -g=whole file at once -e=execute
# Each struct, where typedef comes right after, but not struct or enum
# Note: Struct may contain another scope inside for the union definition, which has { }
perl -p -i -g -e 's/(struct\s[\w\d]+\s\{[^\}]+(?:union\s+\{[^\}]+\};[^\}]+)?\};\s)(typedef\s(?!struct|enum)[^\n]+)/$1\n\nstruct ____TRANSLATIONFIX____;\n$2/g' cimgui.h
popd

printf " --- Copy cimgui to include & lib\n\n"
cp cimgui/*.a lib/
cp cimgui/*.h include/
cp cimgui/*.cpp include/
# Keep a copy at its original place. For the next run
cp include/cimgui_impl.h cimgui/generator/output/
cp include/cimgui_impl.cpp cimgui/generator/output/

printf " --- Generate cimplot\n\n"
pushd cimplot/generator
  luajit ./generator.lua gcc $TARGETS_CIMPLOT $CFLAGS &> /dev/null
popd

printf " --- Build cimplot\n\n"
pushd cimplot
printf " --- Add ____TRANSLATIONFIX____ to cimplot.h\n\n"
perl -p -i -g -e 's/(struct\s[\w\d]+\s\{[^\}]+(?:union\s+\{[^\}]+\};[^\}]+)?\};\s)(typedef\s(?!struct|enum)[^\n]+)/$1\n\nstruct ____TRANSLATIONFIX____;\n$2/g' cimplot.h
popd

printf " --- Copy cimplot to include & lib\n\n"
cp cimplot/*.a lib/
cp cimplot/*.cpp include/
cp cimplot/*.h include/
# Keep a copy at its original place. For the next run
cp include/cimplot.h cimplot/generator/output/
cp include/cimplot.cpp cimplot/generator/output/

#printf "Remove Asserts"
#perl -p -i -g -e 's/(IM_ASSERT\(ImGuiImplVulkanFuncs_vkCmdBeginRenderingKHR != nullptr\);)/\/\/$1/g' cimgui/imgui/backends/imgui_impl_vulkan.cpp
#perl -p -i -g -e 's/(IM_ASSERT\(ImGuiImplVulkanFuncs_vkCmdEndRenderingKHR != nullptr\);)/\/\/$1/g' cimgui/imgui/backends/imgui_impl_vulkan.cpp
#perl -p -i -g -e 's/(IM_ASSERT\(info->ImageCount >= info->MinImageCount\);)/\/\/$1/g' cimgui/imgui/backends/imgui_impl_vulkan.cpp

printf " --- Copy imgui to ./include/imgui\nNote, ./cimgui/imgui submodule is copied, instead of ./imgui\n\n"
pushd cimgui/imgui
  git checkout-index -a -f --prefix=$SCRIPT_DIR/include/imgui/
popd

printf " --- Copy implot to ./include/implot\n\n"
pushd cimplot/implot
  git checkout-index -a -f --prefix=$SCRIPT_DIR/include/implot/
popd

pushd include
  printf " --- Translate to V\n\n"
  printf "[project]\nadditional_flags = \"$DFLAGS\"\n" > c2v.toml
  v translate cimgui.h #&> /dev/null
  v translate cimplot.h #&> /dev/null
popd

printf " --- Move implot&gui.v\n\n"
mv -f include/cimplot.v implot/implot.v
mv -f include/cimgui.v imgui.v

printf " --- Clean generated imgui & implot bindings\n\n"
./cleanup_imgui_implot.perl imgui.v imgui.v imgui
./cleanup_imgui_implot.perl implot/implot.v implot/implot.v implot
v fmt -w imgui.v
# Do not run v fmt on the generated ImPlot binding. ImPlotSpec has a C field
# named `Marker` whose V type is also `Marker`; the formatter currently
# collapses `Marker Marker` to `Marker`, producing invalid V source.

printf " --- Build vimgui\n\n"
./build_vimgui.sh

popd >/dev/null
