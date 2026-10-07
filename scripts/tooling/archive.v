// Extracts archives for build tooling while validating entry paths.
module tooling

import os
import compress.szip

fn validate_zip(path string) ! {
	mut archive := szip.open(path, .no_compression, .read_only)!
	defer { archive.close() }
	for index in 0 .. archive.total()! {
		archive.open_entry_by_index(index)!
		name := archive.name().replace('\\', '/')
		if name.starts_with('/') || name.contains(':') || name.split('/').contains('..') {
			return error('Unsafe archive entry: ${name}')
		}
		archive.close_entry()
	}
}

pub fn extract_zip(path string, destination string) ! {
	validate_zip(path)!
	os.mkdir_all(destination)!
	if !szip.extract_zip_to_dir(path, destination)! {
		return error('Could not extract ${path}')
	}
}
