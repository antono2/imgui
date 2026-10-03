#!/usr/bin/env -S v run

// Configure the generated Vulkan backend ABI for the selected ImGui variant.

import os

const pipeline_begin = '\t// VIMGUI_DOCKING_PIPELINE_BEGIN'
const pipeline_end = '\t// VIMGUI_DOCKING_PIPELINE_END'
const init_begin = '\t// VIMGUI_DOCKING_INIT_BEGIN'
const init_end = '\t// VIMGUI_DOCKING_INIT_END'

fn usage() {
	eprintln('Usage: ./scripts/configure_variant.vsh standard|docking')
}

fn remove_marked_block(lines []string, begin string, end string) ![]string {
	mut output := []string{cap: lines.len}
	mut inside := false
	for line in lines {
		if line == begin {
			if inside {
				return error('nested variant marker ${begin}')
			}
			inside = true
			continue
		}
		if line == end {
			if !inside {
				return error('variant end marker without start: ${end}')
			}
			inside = false
			continue
		}
		if !inside { output << line }
	}
	if inside {
		return error('missing variant end marker ${end}')
	}
	return output
}

fn insert_after_field_once(input string, field string, typ string, addition string) !string {
	mut output := []string{}
	mut count := 0
	for line in input.split_into_lines() {
		output << line
		if line.trim_space().fields() == [field, typ] {
			count++
			output << addition.trim_right('\n')
		}
	}
	if count != 1 {
		return error('expected one ${field} ${typ} field, found ${count}')
	}
	return output.join('\n') + '\n'
}

fn self_test() {
	assert (insert_after_field_once('\tfield   SomeType\n', 'field', 'SomeType', '\tother OtherType\n') or {
		''
	}) == '\tfield   SomeType\n\tother OtherType\n'
	assert (insert_after_field_once('\tfield SomeType\n\tfield SomeType\n', 'field',
		'SomeType', '\tother OtherType\n') or { '' }) == ''
	println('configure_variant.vsh self-test passed')
}

fn main() {
	if os.args.len == 2 && os.args[1] == '--self-test' {
		self_test()
		return
	}
	if os.args.len != 2 || os.args[1] !in ['standard', 'docking'] {
		usage()
		exit(2)
	}
	variant := os.args[1]
	repo_dir := os.dir(@DIR)
	binding := os.join_path(repo_dir, 'impl_vulkan', 'imgui_impl_vulkan.c.v')
	mut lines := os.read_lines(binding) or {
		eprintln(err)
		exit(1)
	}
	lines = remove_marked_block(lines, pipeline_begin, pipeline_end) or {
		eprintln(err)
		exit(1)
	}
	lines = remove_marked_block(lines, init_begin, init_end) or {
		eprintln(err)
		exit(1)
	}
	mut source := lines.join('\n') + '\n'
	if variant == 'docking' {
		source = insert_after_field_once(source, 'pipeline_rendering_create_info',
			'vk.PipelineRenderingCreateInfoKHR', '${pipeline_begin}\n\tswap_chain_image_usage vk.ImageUsageFlags\n${pipeline_end}\n') or {
			eprintln(err)
			exit(1)
		}
		source = insert_after_field_once(source, 'pipeline_info_main', 'PipelineInfo',
			'${init_begin}\n\tpipeline_info_for_viewports PipelineInfo\n${init_end}\n') or {
			eprintln(err)
			exit(1)
		}
	}
	os.write_file(binding, source) or {
		eprintln(err)
		exit(1)
	}
	result := os.execute('${os.quoted_path(@VEXE)} fmt -w ${os.quoted_path(binding)}')
	if result.output.trim_space() != '' { println(result.output.trim_right('\r\n')) }
	if result.exit_code != 0 { exit(result.exit_code) }
}
