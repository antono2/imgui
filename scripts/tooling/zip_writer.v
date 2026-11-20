// Writes ZIP32 archives with executable modes and deterministic timestamps.
module tooling

import os
import compress.deflate
import hash.crc32

const zip_record_limit = 65_535
const zip32_limit = u64(0xffffffff)
const deflate_version = u16(20)
const unix_creator = u16(0x0314)
const utf8_names = u16(0x0800)
const deflate_method = u16(8)
const minimum_dos_date = u16(0x0021) // 1980-01-01

struct ZipEntry {
	name       string
	crc        u32
	compressed u32
	original   u32
	offset     u32
	mode       u32
}

struct ZipWriter {
mut:
	file    os.File
	offset  u64
	entries []ZipEntry
}

fn le16(mut bytes []u8, value u16) {
	bytes << u8(value)
	bytes << u8(value >> 8)
}

fn le32(mut bytes []u8, value u32) {
	for shift in [0, 8, 16, 24] {
		bytes << u8(value >> shift)
	}
}

fn new_zip(path string) !ZipWriter {
	return ZipWriter{
		file: os.create(path)!
	}
}

fn (mut zip ZipWriter) close() {
	zip.file.close()
}

fn (mut zip ZipWriter) write(bytes []u8) ! {
	if zip.offset + u64(bytes.len) >= zip32_limit {
		return error('ZIP32 archive exceeds 4 GiB')
	}
	written := zip.file.write(bytes)!
	if written != bytes.len {
		return error('Incomplete ZIP write')
	}
	zip.offset += u64(written)
}

fn (mut zip ZipWriter) add(name string, bytes []u8, mode u32) ! {
	if name.contains_any('\\:\0') || name.split('/').any(it in ['', '.', '..'])
		|| name.len > zip_record_limit {
		return error('Invalid ZIP entry: ${name}')
	}
	if zip.entries.len >= zip_record_limit - 1 || u64(bytes.len) >= zip32_limit {
		return error('ZIP32 limit exceeded')
	}
	compressed := deflate.compress(bytes, format: .raw_deflate)!
	entry := ZipEntry{
		name:       name
		crc:        crc32.sum(bytes)
		compressed: u32(compressed.len)
		original:   u32(bytes.len)
		offset:     u32(zip.offset)
		mode:       mode
	}
	mut header := []u8{}
	le32(mut header, 0x04034b50)
	le16(mut header, deflate_version)
	le16(mut header, utf8_names)
	le16(mut header, deflate_method)
	le16(mut header, 0)
	le16(mut header, minimum_dos_date)
	le32(mut header, entry.crc)
	le32(mut header, entry.compressed)
	le32(mut header, entry.original)
	le16(mut header, u16(name.len))
	le16(mut header, 0)
	header << name.bytes()
	zip.write(header)!
	zip.write(compressed)!
	zip.entries << entry
}

fn (mut zip ZipWriter) finish() ! {
	central_offset := u32(zip.offset)
	for entry in zip.entries {
		mut header := []u8{}
		le32(mut header, 0x02014b50)
		le16(mut header, unix_creator)
		le16(mut header, deflate_version)
		le16(mut header, utf8_names)
		le16(mut header, deflate_method)
		le16(mut header, 0)
		le16(mut header, minimum_dos_date)
		le32(mut header, entry.crc)
		le32(mut header, entry.compressed)
		le32(mut header, entry.original)
		le16(mut header, u16(entry.name.len))
		le16(mut header, 0)
		le16(mut header, 0)
		le16(mut header, 0)
		le16(mut header, 0)
		le32(mut header, entry.mode << 16)
		le32(mut header, entry.offset)
		header << entry.name.bytes()
		zip.write(header)!
	}
	central_size := u32(zip.offset) - central_offset
	mut end := []u8{}
	le32(mut end, 0x06054b50)
	le16(mut end, 0)
	le16(mut end, 0)
	le16(mut end, u16(zip.entries.len))
	le16(mut end, u16(zip.entries.len))
	le32(mut end, central_size)
	le32(mut end, central_offset)
	le16(mut end, 0)
	zip.write(end)!
}

pub struct ZipFile {
pub:
	name string
	path string
	mode u32 = 0o644
}

pub fn write_zip(path string, files []ZipFile) ! {
	mut zip := new_zip(path)!
	defer { zip.close() }
	mut seen := map[string]bool{}
	for file in files {
		if file.name in seen {
			return error('Duplicate ZIP entry: ${file.name}')
		}
		seen[file.name] = true
		zip.add(file.name, os.read_bytes(file.path)!, u32(0o100000) | (file.mode & 0o777))!
	}
	zip.finish()!
}
