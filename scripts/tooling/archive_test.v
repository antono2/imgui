// Checks archive extraction, path safety and failure handling with temporary fixtures.
module tooling

import os
import compress.szip

fn test_extract_nested_unicode_archive() {
	root := os.join_path(os.temp_dir(), 'imgui-tooling-zip-${os.getpid()}')
	os.mkdir_all(root) or { panic(err) }
	defer { os.rmdir_all(root) or {} }
	path := os.join_path(root, 'input.zip')
	mut zip := szip.open(path, .no_compression, .write) or { panic(err) }
	zip.open_entry('nested folder/世界.txt') or { panic(err) }
	zip.write_entry('archive contents'.bytes()) or { panic(err) }
	zip.close_entry()
	zip.close()
	destination := os.join_path(root, 'extracted')
	extract_zip(path, destination) or { panic(err) }
	assert os.read_file(os.join_path(destination, 'nested folder', '世界.txt')) or { panic(err) } == 'archive contents'
}

fn test_invalid_archive_fails_before_creating_destination() {
	root := os.join_path(os.temp_dir(), 'imgui-tooling-invalid-zip-${os.getpid()}')
	os.mkdir_all(root) or { panic(err) }
	defer { os.rmdir_all(root) or {} }
	path := os.join_path(root, 'invalid.zip')
	os.write_file(path, 'not a zip') or { panic(err) }
	destination := os.join_path(root, 'extracted')
	extract_zip(path, destination) or {
		assert !os.exists(destination)
		return
	}
	assert false, 'Invalid archive was reported as successfully extracted'
}
