#!/usr/bin/env bash
set -euo pipefail

regenerate_c=0
while (($#)); do
	case "$1" in
		--regenerate-c) regenerate_c=1; shift ;;
		-h|--help)
			printf '%s\n' 'Usage: generate_v.sh [--regenerate-c]'
			printf '%s\n' 'By default, translate the generated C API committed by cimgui/cimplot.'
			exit 0 ;;
		*) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
	esac
done

# Make sure the current working dir = this script dir
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
pushd "$SCRIPT_DIR" >/dev/null
printf " --- Changed working dir to\n$SCRIPT_DIR\n\n"

TARGETS_CIMGUI="internal" #"comments constructors internal noimstrv"
TARGETS_CIMPLOT="internal"
#DFLAGS="-DCMAKE_BUILD_TYPE=RelWithDebInfo -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=ON -DIMGUI_STATIC=ON -DCIMGUI_NO_EXPORT=ON -DCIMGUI_USE_GLFW=ON"
DFLAGS="-DSTATIC_BUILD=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=ON -DIMGUI_STATIC=OFF -DCIMGUI_NO_EXPORT=ON -DCIMGUI_USE_GLFW=ON"
CFLAGS="glfw" #opengl3 opengl2 sdl2 sdl3"

printf " --- Generate cimgui\n\n"
rm -f cimgui/CMakeCache.txt cimplot/CMakeCache.txt CMakeCache.txt
if ((regenerate_c)); then
	pushd cimgui/generator
	# ./generator.lua <compiler> "<targets>" <CFLAGS>
	luajit ./generator.lua gcc $TARGETS_CIMGUI $CFLAGS &> /dev/null
	popd
else
	printf "     Using the generated API committed by the pinned cimgui revision\n"
fi

printf " --- Copy cimgui to include\n\n"
cp cimgui/*.h include/
cp cimgui/*.cpp include/

printf " --- Add ____TRANSLATIONFIX____ to include/cimgui.h\n\n"
# -p=print each line -i=edit in place -g=whole file at once -e=execute
# Each struct, where typedef comes right after, but not struct or enum
# Note: Struct may contain another scope inside for the union definition, which has { }
perl -p -i -g -e 's/(struct\s[\w\d]+\s\{[^\}]+(?:union\s+\{[^\}]+\};[^\}]+)?\};\s)(typedef\s(?!struct|enum)[^\n]+)/$1\n\nstruct ____TRANSLATIONFIX____;\n$2/g' include/cimgui.h

printf " --- Generate cimplot\n\n"
if ((regenerate_c)); then
	pushd cimplot/generator
	luajit ./generator.lua gcc $TARGETS_CIMPLOT $CFLAGS &> /dev/null
	popd
else
	printf "     Using the generated API committed by the pinned cimplot revision\n"
fi

printf " --- Copy cimplot to include\n\n"
cp cimplot/*.cpp include/
cp cimplot/*.h include/

printf " --- Add ____TRANSLATIONFIX____ to include/cimplot.h\n\n"
perl -p -i -g -e 's/(struct\s[\w\d]+\s\{[^\}]+(?:union\s+\{[^\}]+\};[^\}]+)?\};\s)(typedef\s(?!struct|enum)[^\n]+)/$1\n\nstruct ____TRANSLATIONFIX____;\n$2/g' include/cimplot.h

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
	# v translate leaves machine-specific Clang AST metadata behind. It is not
	# needed by the bindings and contains absolute builder and system paths.
	rm -f cimgui.json cimplot.json
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
v run build_vimgui.vsh

popd >/dev/null
