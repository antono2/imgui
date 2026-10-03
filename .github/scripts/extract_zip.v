module main
import os
import compress.szip
fn main() {
    if os.args.len != 3 { eprintln('Usage: v run extract_zip.v archive.zip destination'); exit(2) }
    run(os.args[1], os.args[2]) or { eprintln(err); exit(1) }
}
fn run(path string, destination string) ! {
    mut archive := szip.open(path, .no_compression, .read_only)!
    for index in 0 .. archive.total()! {
        archive.open_entry_by_index(index)!
        name := archive.name().replace('\\', '/')
        if name.starts_with('/') || name.contains(':') || name.split('/').contains('..') {
            archive.close()
            return error('Unsafe archive entry: ${name}')
        }
        archive.close_entry()
    }
    archive.close()
    os.mkdir_all(destination)!
    if !szip.extract_zip_to_dir(path, destination)! { return error('Could not extract ${path}') }
}
