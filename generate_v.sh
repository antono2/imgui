#!/bin/bash

# Make sure the current working dir = this script dir
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR
printf " --- Changed working dir to\n$SCRIPT_DIR\n\n"

git submodule update --init --recursive
git submodule foreach git pull

TARGETS_CIMGUI="internal" #"comments constructors internal noimstrv"
TARGETS_CIMPLOT="internal"
CFLAGS="glfw opengl3 opengl2 sdl2 sdl3"
DFLAGS="-DCMAKE_BUILD_TYPE=RelWithDebInfo -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=ON -DIMGUI_STATIC=ON -DCIMGUI_NO_EXPORT=ON"

printf " --- Generate cimgui\n\n"
# rm cimgui/CMakeCache.txt
pushd cimgui/generator
  # ./generator.lua <compiler> "<targets>" <CFLAGS>
  luajit ./generator.lua gcc $TARGETS_CIMGUI $CFLAGS &> /dev/null
popd
pushd cimgui
  cmake $DFLAGS $CFLAGS . &> /dev/null
  make VERBOSE=1 &> /dev/null
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
# rm cimplot/CMakeCache.txt
pushd cimplot/generator
  luajit ./generator.lua gcc $TARGETS_CIMPLOT $CFLAGS &> /dev/null
popd
pushd cimplot
  cmake $DFLAGS $CFLAGS . &> /dev/null
  make &> /dev/null
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
  v translate cimgui.h &> /dev/null
  v translate cimplot.h &> /dev/null
popd

printf " --- Move implot&gui.v\n\n"
mv include/cimplot.v src/implot.v
mv include/cimgui.v src/imgui.v

printf " --- Cleanup src/implot&gui.v\n\n"
./cleanup_imgui.perl
./cleanup_implot.perl
v fmt -w src/imgui.v &> /dev/null
v fmt -w src/implot.v &> /dev/null

# As ~/.vmodules/imgui/imgui leads to import issue, make sure there is no imgui dir
rm -rf ./imgui

popd
