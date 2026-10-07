#!/usr/bin/env bash
# Updates the selected upstream variant and regenerates bindings for maintainer review.
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: update_upstream.sh standard|docking [--check-only] [--regenerate-c]

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
check_only=false
while (($#)); do
	case "$1" in
		--check-only) check_only=true; shift ;;
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

upstream_head() {
	local module=$1 branch=$2 head
	head=$(git -C "$module" ls-remote --heads origin "$branch" | awk '{print $1}')
	[[ $head =~ ^[0-9a-f]{40}$ ]] || {
		printf 'Could not resolve %s origin/%s to one commit.\n' "$module" "$branch" >&2
		exit 1
	}
	printf '%s\n' "$head"
}

cimgui_head=$(upstream_head cimgui "$cimgui_branch")
cimplot_head=$(upstream_head cimplot master)
if [[ $(git -C cimgui rev-parse HEAD) == "$cimgui_head" &&
	$(git -C cimplot rev-parse HEAD) == "$cimplot_head" ]]; then
	printf 'changed=false\n'
	if $check_only; then exit 0; fi
else
	printf 'changed=true\n'
	if $check_only; then exit 0; fi
fi

fetch_upstream() {
	local module=$1 branch=$2
	# actions/checkout fetches submodules with --depth=1. A shallow graph
	# cannot prove that the upstream revision descends from our pinned one.
	if [[ $(git -C "$module" rev-parse --is-shallow-repository) == true ]]; then
		git -C "$module" fetch --unshallow origin "$branch"
	else
		git -C "$module" fetch origin "$branch"
	fi
}

fetch_upstream cimgui "$cimgui_branch"
[[ $(git -C cimgui rev-parse FETCH_HEAD) == "$cimgui_head" ]] || {
	printf 'cimgui origin/%s moved during update; retry later.\n' "$cimgui_branch" >&2
	exit 1
}
git -C cimgui merge-base --is-ancestor HEAD FETCH_HEAD || {
	printf 'cimgui origin/%s is not a fast-forward update.\n' "$cimgui_branch" >&2
	exit 1
}
git -C cimgui switch --detach FETCH_HEAD
git -C cimgui submodule update --init --recursive

fetch_upstream cimplot master
[[ $(git -C cimplot rev-parse FETCH_HEAD) == "$cimplot_head" ]] || {
	printf 'cimplot origin/master moved during update; retry later.\n' >&2
	exit 1
}
git -C cimplot merge-base --is-ancestor HEAD FETCH_HEAD || {
	printf 'cimplot origin/master is not a fast-forward update.\n' >&2
	exit 1
}
git -C cimplot switch --detach FETCH_HEAD
git -C cimplot submodule update --init --recursive

printf '%s\n' "$variant" > UPSTREAM_VARIANT
./scripts/configure_variant.vsh "$variant"
./generate.vsh "${regenerate_arg[@]}"

printf 'Updated %s bindings: cimgui=%s cimplot=%s\n' \
	"$variant" \
	"$(git -C cimgui rev-parse --short HEAD)" \
	"$(git -C cimplot rev-parse --short HEAD)"
