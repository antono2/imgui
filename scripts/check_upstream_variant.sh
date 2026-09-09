#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)
variant=$(tr -d '[:space:]' < "$repo_dir/UPSTREAM_VARIANT")
header="$repo_dir/include/cimgui.h"

case "$variant" in
	docking)
		grep -q '^//docking branch$' "$header" || {
			echo 'UPSTREAM_VARIANT says docking, but include/cimgui.h is standard.' >&2
			exit 1
		} ;;
	standard)
		if grep -q '^//docking branch$' "$header"; then
			echo 'UPSTREAM_VARIANT says standard, but include/cimgui.h is docking.' >&2
			exit 1
		fi ;;
	*)
		printf 'Unknown UPSTREAM_VARIANT: %s\n' "$variant" >&2
		exit 1 ;;
esac

version=$(sed -n 's#^//based on imgui.h file version "\([^"]*\)".*#\1#p' "$header" | head -1)
[[ -n $version ]] || {
	echo 'Could not determine Dear ImGui version from include/cimgui.h.' >&2
	exit 1
}
grep -Fq "pub const version = '$version'" "$repo_dir/imgui.v" || {
	printf 'imgui.v version does not match include/cimgui.h (%s).\n' "$version" >&2
	exit 1
}

printf 'Dear ImGui %s (%s variant)\n' "$version" "$variant"
