// Verify staged demo ZIPs and publish them with their upstream variant.
module tooling

import crypto.sha256
import os

pub fn demo_variant(root string) !string {
	variant := os.read_file(os.join_path(root, 'UPSTREAM_VARIANT'))!.trim_space()
	if variant !in ['docking', 'standard'] {
		return error('Unsupported ImGui variant: ${variant}')
	}
	return variant
}

pub fn publish_demo_archive(output string, stage string, name string, files []ZipFile) ! {
	archive_name := name + '.zip'
	temporary_archive := os.join_path(stage, archive_name)
	write_zip(temporary_archive, files)!
	verify_written_zip(temporary_archive, files, os.join_path(stage, 'verify-entry'))!
	checksum := sha256.sum(os.read_bytes(temporary_archive)!).hex()
	os.mv(temporary_archive, os.join_path(output, archive_name))!
	println('${checksum}  ${archive_name}')
}

pub fn write_demo_variant(output string, variant string) ! {
	if output == '' {
		return
	}
	mut receipt := os.open_append(output)!
	defer { receipt.close() }
	receipt.writeln('name=${variant}')!
}
