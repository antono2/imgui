#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: update_upstream.sh standard|docking [--regenerate-c]

Update the cimgui and cimplot gitlinks to their selected current upstream
branches, regenerate the V bindings, and rebuild libvimgui.
EOF
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
	usage
	exit 0
fi

variant=${1:-}
[[ $variant == standard || $variant == docking ]] || {
	usage >&2
	exit 2
}
shift

regenerate_arg=()
while (($#)); do
	case "$1" in
		--regenerate-c) regenerate_arg=(--regenerate-c); shift ;;
		-h|--help) usage; exit 0 ;;
		*) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
	esac
done

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)
cd "$repo_dir"

for module in cimgui cimplot; do
	[[ -z $(git -C "$module" status --porcelain) ]] || {
		printf '%s has local changes; preserve or discard them before updating upstream.\n' "$module" >&2
		exit 1
	}
done

cimgui_branch=master
[[ $variant == docking ]] && cimgui_branch=docking_inter

git -C cimgui fetch origin "$cimgui_branch"
git -C cimgui switch --detach FETCH_HEAD
git -C cimgui submodule update --init --recursive

git -C cimplot fetch origin master
git -C cimplot switch --detach FETCH_HEAD
git -C cimplot submodule update --init --recursive

printf '%s\n' "$variant" > UPSTREAM_VARIANT
./scripts/configure_variant.sh "$variant"
v run generate.vsh "${regenerate_arg[@]}"

printf 'Updated %s bindings: cimgui=%s cimplot=%s\n' \
	"$variant" \
	"$(git -C cimgui rev-parse --short HEAD)" \
	"$(git -C cimplot rev-parse --short HEAD)"
