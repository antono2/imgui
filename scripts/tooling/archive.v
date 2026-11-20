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

// Require nonempty files at the exact paths used by Android's APK loader.
pub fn require_zip_files(path string, names []string) ! {
	mut zip := szip.open(path, .no_compression, .read_only)!
	defer { zip.close() }
	mut present := map[string]bool{}
	for index in 0 .. zip.total()! {
		zip.open_entry_by_index(index)!
		name := zip.name()
		if name in names {
			if name in present || zip.is_dir()! || zip.size() == 0 {
				return error('Duplicate, empty or non-file ZIP entry: ${name}')
			}
			present[name] = true
		}
		zip.close_entry()
	}
	for name in names {
		if name !in present {
			return error('Missing ZIP entry: ${name}')
		}
	}
}

// Read each staged file back from the archive and compare its exact bytes.
pub fn verify_written_zip(path string, files []ZipFile, scratch string) ! {
	mut zip := szip.open(path, .no_compression, .read_only)!
	defer { zip.close() }
	if zip.total()! != files.len {
		return error('ZIP entry count differs from staged files')
	}
	for file in files {
		zip.open_entry(file.name)!
		if zip.is_dir()! {
			return error('Expected a file in the ZIP: ${file.name}')
		}
		zip.extract_entry(scratch)!
		if os.read_bytes(scratch)! != os.read_bytes(file.path)! {
			return error('ZIP payload differs from the staged file: ${file.name}')
		}
		os.rm(scratch)!
		zip.close_entry()
	}
}
