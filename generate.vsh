#!/usr/bin/env -S v

/*
  This script will generate Dear ImGui bindings for V and build vimgui lib
*/
import arrays

const wd = @DIR
const no_sh_output = true

const targets_cimgui = 'internal' //"comments constructors internal noimstrv"
const targets_cimplot = 'internal'
const cflags = 'glfw opengl3 opengl2 sdl2 sdl3'
// const dflags = "-DCMAKE_BUILD_TYPE=RelWithDebInfo -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=ON -DIMGUI_STATIC=ON -DCIMGUI_NO_EXPORT=ON -DCIMGUI_USE_GLFW=ON"
const dflags = '-DSTATIC_BUILD=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=ON -DIMGUI_STATIC=OFF -DCIMGUI_NO_EXPORT=ON -DCIMGUI_USE_GLFW=ON'

// print command then execute it
fn sh(cmd string) {
	println('❯ ${cmd}')
	if !no_sh_output {
		print(execute_or_exit(cmd).output)
	} else {
		execute_or_exit(cmd)
	}
}

// Change directory or panic
fn cd(dir string) {
	chdir(dir) or { panic('Could not change working directory to ${dir}') }
}

// Copy file or panic
fn mcp(src string, dst string) {
	cp(src, dst) or { panic('Could not copy ${src} to ${dst}. ${err}') }
}

// Copy files where extension matches item in []ext
fn copy_by_ext(src string, dst string, ext []string) {
	entries := ls(src) or { [] }
	for entry in entries {
		fpath := join_path(src, entry)
		if !is_dir(fpath) && arrays.binary_search(ext, file_ext(entry)) or { continue } > -1 {
			mcp(fpath, '${dst}/${entry}')
		}
	}
}

// START
cd(wd)

println(' --- Updating Submodules')
println('     Note: Change submodule version to change cimgui version')
/*
if exists('${wd}/cimgui/cimgui.h') {
  cd('${wd}/cimgui')
  sh('git stash')
  cd('${wd}')
}
if exists('${wd}/cimplot/cimplot.h') {
  cd('${wd}/cimplot')
  sh('git stash')
  cd('${wd}')
}
*/
if !exists('${wd}/cimgui/cimgui.h') {
	sh('git submodule update --init --recursive')
	// sh('git submodule foreach git pull')
}

println(' --- Generate cimgui')
cd('${wd}/cimgui/generator')
// ./generator.lua <compiler> "<targets>" <CFLAGS>
sh('luajit generator.lua gcc ${targets_cimgui} ${cflags}')

println(' --- Add ____TRANSLATIONFIX____ to cimgui.h')
cd('${wd}/cimgui')
/*
  -p=print each line -i=edit in place -g=whole file at once -e=execute
  Each struct, where typedef comes right after, but not struct or enum
  Note: Struct may contain another scope inside for the union definition, which has { }
*/
sh("perl -p -i -g -e 's/(struct\\s[\\w\\d]+\\s\\{[^\\}]+(?:union\\s+\\{[^\\}]+\\};[^\\}]+)?\\};\\s)(typedef\\s(?!struct|enum)[^\\n]+)/$1\\n\\nstruct ____TRANSLATIONFIX____;\\n$2/g' cimgui.h")

println(' --- Copy cimgui to include')
copy_by_ext('${wd}/cimgui', '${wd}/include', ['.h', '.cpp'])

// Keep a copy at its original place. For the next run
mcp('${wd}/include/cimgui_impl.h', '${wd}/cimgui/generator/output/cimgui_impl.h')
mcp('${wd}/include/cimgui_impl.cpp', '${wd}/cimgui/generator/output/cimgui_impl.cpp')

println(' --- Generate cimplot')
cd('${wd}/cimplot/generator')
sh('luajit generator.lua gcc ${targets_cimplot} ${cflags}')

println(' --- Add ____TRANSLATIONFIX____ to cimplot.h')
cd('${wd}/cimplot')
sh("perl -p -i -g -e 's/(struct\\s[\\w\\d]+\\s\\{[^\\}]+(?:union\\s+\\{[^\\}]+\\};[^\\}]+)?\\};\\s)(typedef\\s(?!struct|enum)[^\\n]+)/$1\\n\\nstruct ____TRANSLATIONFIX____;\\n$2/g' cimplot.h")

println(' --- Copy cimplot to include')
copy_by_ext('${wd}/cimplot', '${wd}/include', ['.h', '.cpp'])

// Keep a copy at its original place. For the next run
mcp('${wd}/include/cimplot.h', '${wd}/cimplot/generator/output/cimplot.h')
mcp('${wd}/include/cimplot.cpp', '${wd}/cimplot/generator/output/cimplot.cpp')

println(' --- Copy imgui to ./include/imgui')
println('     Note, ./cimgui/imgui submodule is copied')
cd('${wd}/cimgui/imgui')
sh('git checkout-index -a -f --prefix=${wd}/include/imgui/')

println(' --- Copy implot to ./include/implot')
cd('${wd}/cimplot/implot')
sh('git checkout-index -a -f --prefix=${wd}/include/implot/')

println(' --- Translate to V')
cd('${wd}/include')
write_file('${wd}/include/c2v.toml', '[project]\nadditional_flags = "${dflags}"') or {
	panic('Could not write ${wd}/include/c2v.toml')
}
sh('v translate cimgui.h')
sh('v translate cimplot.h')
// v translate leaves machine-specific Clang AST metadata behind. It is not
// needed by the bindings and contains absolute builder and system paths.
rm('${wd}/include/cimgui.json') or {}
rm('${wd}/include/cimplot.json') or {}

println(' --- Move implot&gui.v')
mv('${wd}/include/cimgui.v', '${wd}/imgui.v', overwrite: true) or {
	panic('Could not move ${wd}/include/cimgui.v to ${wd}/imgui.v')
}
mv('${wd}/include/cimplot.v', '${wd}/implot/implot.v', overwrite: true) or {
	panic('Could not move ${wd}/include/cimplot.v to ${wd}/implot/implot.v')
}

println(' --- Cleanup generated implot&gui.v')
cd(wd)
sh('${wd}/cleanup_imgui_implot.perl ${wd}/imgui.v ${wd}/imgui.v imgui')
sh('${wd}/cleanup_imgui_implot.perl ${wd}/implot/implot.v ${wd}/implot/implot.v implot')
sh('v fmt -w ${wd}/imgui.v')
sh('v fmt -w ${wd}/implot/implot.v')

println('--- Build vimgui')
sh('${wd}/build_vimgui.sh')

println('GENERATED')
println('${wd}/imgui.v')
println('${wd}/implot/implot.v')
