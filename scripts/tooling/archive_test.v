// Checks archive extraction, path safety and failure handling with temporary fixtures.
module tooling

import os
import compress.szip
import encoding.binary

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

fn test_written_zip_preserves_executable_modes_and_requires_exact_members() {
	root := os.join_path(os.temp_dir(), 'imgui-tooling-write-zip-${os.getpid()}')
	os.mkdir(root) or { panic(err) }
	defer { os.rmdir_all(root) or {} }
	dex := os.join_path(root, 'bytecode')
	empty := os.join_path(root, 'empty')
	os.write_file(dex, 'test payload') or { panic(err) }
	os.write_file(empty, '') or { panic(err) }
	files := [
		ZipFile{
			name: 'package/demo'
			path: dex
			mode: 0o755
		},
		ZipFile{
			name: 'nested/classes.dex'
			path: dex
		},
		ZipFile{
			name: 'assets/empty'
			path: empty
		},
	]
	archive := os.join_path(root, 'bundle.zip')
	scratch := os.join_path(root, 'readback')
	write_zip(archive, files) or { panic(err) }
	verify_written_zip(archive, files, scratch) or { panic(err) }
	require_zip_files(archive, ['nested/classes.dex']) or { panic(err) }
	// The writer emits a 22-byte end record with no comment, then the central
	// directory offset is at byte 16 of that record.
	data := os.read_bytes(archive) or { panic(err) }
	central := int(binary.little_endian_u32_at(data, data.len - 22 + 16))
	assert binary.little_endian_u32_at(data, central) == u32(0x02014b50)
	assert binary.little_endian_u32_at(data, central + 38) >> 16 == u32(0o100755)
	mut missing := false
	require_zip_files(archive, ['classes.dex']) or {
		assert err.msg().contains('Missing ZIP entry: classes.dex')
		missing = true
	}
	assert missing
	mut refused_empty := false
	require_zip_files(archive, ['assets/empty']) or {
		assert err.msg().contains('empty or non-file')
		refused_empty = true
	}
	assert refused_empty
}
