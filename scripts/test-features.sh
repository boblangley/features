#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
staging_root="$(mktemp -d)"

cleanup() {
    rm -rf "${staging_root}"
}
trap cleanup EXIT

mkdir -p "${staging_root}/src" "${staging_root}/test"
cp -a "${repo_root}/src/features/." "${staging_root}/src/"
cp -a "${repo_root}/test/features/." "${staging_root}/test/"

devcontainer features test --project-folder "${staging_root}" "$@"
