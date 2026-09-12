#!/usr/bin/env -S v run

// Verify that the checked-in source, ABI layout, and public markers agree.

import os

fn fail(message string) {
	eprintln(message)
	exit(1)
}

fn struct_fields(source string, declaration string) []string {
	start := source.index(declaration) or { return [] }
	mut fields := []string{}
	for line in source[start..].split_into_lines()[1..] {
		text := line.trim_space()
		if text == '}' {
			break
		}
		if text != '' && text != 'pub mut:' { fields << text.fields().join(' ') }
	}
	return fields
}

fn main() {
	repo_dir := os.dir(@DIR)
	variant := os.read_file(os.join_path(repo_dir, 'UPSTREAM_VARIANT')) or {
		fail(err.msg())
		''
	}.trim_space()
	header := os.read_file(os.join_path(repo_dir, 'include', 'cimgui.h')) or {
		fail(err.msg())
		''
	}
	binding := os.read_file(os.join_path(repo_dir, 'impl_vulkan', 'imgui_impl_vulkan.c.v')) or {
		fail(err.msg())
		''
	}
	public_variant := os.read_file(os.join_path(repo_dir, 'variant.v')) or {
		fail(err.msg())
		''
	}
	runtime_header := os.read_file(os.join_path(repo_dir, 'vimgui_variant.h')) or {
		fail(err.msg())
		''
	}

	match variant {
		'docking' {
			if !header.split_into_lines().contains('//docking branch') {
				fail('UPSTREAM_VARIANT says docking, but include/cimgui.h is standard.')
			}
			if !binding.contains('VIMGUI_DOCKING_INIT_BEGIN') {
				fail('The docking Vulkan backend layout is not configured.')
			}
			if !public_variant.contains("pub const upstream_variant = 'docking'") {
				fail('The public runtime variant marker does not say docking.')
			}
			if !runtime_header.contains('ImGuiConfigFlags_DockingEnable') {
				fail('The docking runtime helpers are not configured.')
			}
		}
		'standard' {
			if header.split_into_lines().contains('//docking branch') {
				fail('UPSTREAM_VARIANT says standard, but include/cimgui.h is docking.')
			}
			if binding.contains('VIMGUI_DOCKING_INIT_BEGIN') {
				fail('The standard Vulkan backend still has docking-only ABI fields.')
			}
			if !public_variant.contains("pub const upstream_variant = 'standard'") {
				fail('The public runtime variant marker does not say standard.')
			}
			if runtime_header.contains('ImGuiConfigFlags_DockingEnable') {
				fail('The standard runtime helpers still reference docking symbols.')
			}
		}
		else { fail('Unknown UPSTREAM_VARIANT: ${variant}') }
	}

	mut version := ''
	for line in header.split_into_lines() {
		if line.starts_with('//based on imgui.h file version "') {
			version = line.all_after('"').all_before('"')
			break
		}
	}
	if version == '' { fail('Could not determine Dear ImGui version from include/cimgui.h.') }
	generated := os.read_file(os.join_path(repo_dir, 'imgui.v')) or {
		fail(err.msg())
		''
	}
	if !generated.contains("pub const version = '${version}'") {
		fail('imgui.v version does not match include/cimgui.h (${version}).')
	}
	if struct_fields(generated, 'pub struct C.ImVec2_c {') != ['x f32', 'y f32']
		|| struct_fields(generated, 'pub struct C.ImVec4_c {') != ['x f32', 'y f32', 'z f32', 'w f32'] {
		fail('Generated ImVec2/ImVec4 layouts are incomplete.')
	}
	if !generated.split_into_lines().contains('pub type ImVec2 = C.ImVec2_c')
		|| !generated.split_into_lines().contains('pub type ImVec4 = C.ImVec4_c') {
		fail('Generated public ImVec2/ImVec4 aliases are missing.')
	}
	println('Dear ImGui ${version} (${variant} variant)')
}
