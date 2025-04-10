#!/bin/bash

# Make sure the current working dir = this script dir
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR
printf " --- Changed working dir to\n$SCRIPT_DIR\n\n"

git submodule update --init --recursive
git submodule foreach git pull
printf " --- Generate cimgui\n\n"
pushd cimgui/generator
# ./generator.lua <compiler> "<targets>" <CFLAGS>
luajit ./generator.lua gcc "comments constructors internal" $CFLAGS
popd
cp cimgui/*.h include/
cp cimgui/*.cpp include/
# Keep a copy at its original place. For the next run
cp include/cimgui_impl.h cimgui/generator/output/
cp include/cimgui_impl.cpp cimgui/generator/output/

printf " --- Generate cimplot\n\n"
pushd cimplot/generator
luajit ./generator.lua gcc "internal" $CFLAGS
popd
cp cimplot/*.cpp include/
cp cimplot/*.h include/
# Keep a copy at its original place. For the next run
cp include/cimplot.h cimplot/generator/output/
cp include/cimplot.cpp cimplot/generator/output/

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

#'additional_flags = "-I . -I imgui -I implot -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS -DIMGUI_USE_WCHAR32 -DCIMGUI_USE_VULKAN -DCIMGUI_USE_GLFW -DCIMGUI_DISABLE_OBSOLETE_FUNCTIONS"' \
printf '[project]\nadditional_flags = "-DCIMGUI_DEFINE_ENUMS_AND_STRUCTS -DIMGUI_USE_WCHAR32"\n' > c2v.toml
v translate cimgui.h
v translate cimplot.h
popd

printf " --- Move implot&gui.v\n\n"
mv include/cimplot.v src/implot.v
mv include/cimgui.v src/imgui.v

printf " --- Cleanup src/implot&gui.v\n\n"
./cleanup_imgui.perl
./cleanup_implot.perl
v fmt -w src/imgui.v &> /dev/null
v fmt -w src/implot.v &> /dev/null


# As src/implot.v is not allowed, move it to another directory
mv src/implot.v modules/implot/implot.v

popd
