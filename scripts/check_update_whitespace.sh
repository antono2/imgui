#!/usr/bin/env bash
# Keep generated V and maintained code strict without rewriting copied Dear ImGui sources.
set -euo pipefail
git diff --check -- . ':(exclude)include/imgui/**'
