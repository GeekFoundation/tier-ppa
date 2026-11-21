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

curl -fsSL \
    "https://api.launchpad.net/1.0/~${ppa_owner}/+archive/ubuntu/${ppa_name}?ws.op=getBuildRecords&source_name=tierd" \
    | jq '.entries[] | {version: .source_package_version, arch: .arch_tag, state: .buildstate}'
