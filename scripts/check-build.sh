#!/usr/bin/env bash
# Show Launchpad build status for tierd across all architectures.
#
# Usage: ./scripts/check-build.sh
#
# Requires: curl, jq

set -euo pipefail

PPA="geekfoundation/tier"
ppa_owner="${PPA%%/*}"
ppa_name="${PPA#*/}"

for cmd in curl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "error: '$cmd' is required but not found" >&2
        exit 1
    fi
done

sources=$(curl -fsSL \
    "https://api.launchpad.net/1.0/~${ppa_owner}/+archive/ubuntu/${ppa_name}?ws.op=getPublishedSources&source_name=tierd")

active_vers=$(echo "$sources" \
    | jq -r '[.entries[] | select(.status == "Published" or .status == "Pending") | .source_package_version] | unique[]')

if [ -z "$active_vers" ]; then
    echo "[]"
    exit 0
fi

all_builds=$(curl -fsSL \
    "https://api.launchpad.net/1.0/~${ppa_owner}/+archive/ubuntu/${ppa_name}?ws.op=getBuildRecords&source_name=tierd")

# Build a single JSON array: one object per active version.
result="[]"
while IFS= read -r ver; do
    source_status=$(echo "$sources" \
        | jq -r --arg v "$ver" '.entries[] | select(.source_package_version == $v) | .status' \
        | head -n1)
    builds=$(echo "$all_builds" \
        | jq --arg v "$ver" '[.entries[] | select(.source_package_version == $v) | {arch: .arch_tag, state: .buildstate}]')
    entry=$(jq -n --arg ver "$ver" --arg st "$source_status" --argjson b "$builds" \
        '{version: $ver, status: $st, builds: $b}')
    result=$(echo "$result" | jq --argjson e "$entry" '. + [$e]')
done <<< "$active_vers"

echo "$result"
