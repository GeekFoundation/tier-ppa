#!/usr/bin/env bash
# Trigger a PPA publish for the latest tier-core tag if not already published.
#
# Fetches the latest release tag from the upstream repo, checks Launchpad
# whether that version (or a pending build for it) already exists in the PPA,
# and triggers the publish-ppa workflow only when it does not.
#
# Usage:
#   ./scripts/trigger-publish.sh
#   ./scripts/trigger-publish.sh --dry-run   # build & sign, skip dput
#
# Requires: gh (GitHub CLI, authenticated), curl, jq

set -euo pipefail

TIER_REPO="tier-org/tier-core"
PPA_REPO="GeekFoundation/tier-ppa"
PPA="geekfoundation/tier"
SERIES="noble"
REVISION="1"
DRY_RUN=false

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *) echo "error: unknown argument: $arg" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
for cmd in gh curl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "error: '$cmd' is required but not found" >&2
        exit 1
    fi
done

step() { echo "==> $*"; }

# ---------------------------------------------------------------------------
# Resolve latest upstream tag
# ---------------------------------------------------------------------------
step "Fetching latest release tag from ${TIER_REPO}"
latest_tag=$(gh api "repos/${TIER_REPO}/releases/latest" --jq '.tag_name')
upver="${latest_tag#v}"
echo "    tag: ${latest_tag}  version: ${upver}"

# ---------------------------------------------------------------------------
# Check Launchpad — skip if already published or pending
# The version in the PPA is <upstream>~<series><revision>.
# We query without a status filter so both Pending and Published entries
# are caught; re-triggering a pending build would create a duplicate upload.
# ---------------------------------------------------------------------------
pkg_version="${upver}~${SERIES}${REVISION}"
ppa_owner="${PPA%%/*}"
ppa_name="${PPA#*/}"

step "Checking Launchpad for tierd ${pkg_version} in ppa:${PPA}"

lp_url="https://api.launchpad.net/1.0/~${ppa_owner}/+archive/ubuntu/${ppa_name}"
lp_url+="?ws.op=getPublishedSources&source_name=tierd&version=${pkg_version}"

count=$(curl -fsSL "$lp_url" | jq '.total_size')

if [ "$count" -gt 0 ]; then
    echo "    tierd ${pkg_version} already exists in ppa:${PPA} (${count} record(s))"
    echo "    Nothing to do. To re-upload the same version, bump REVISION in this script."
    exit 0
fi

echo "    not found — will publish"

# ---------------------------------------------------------------------------
# Trigger the workflow
# ---------------------------------------------------------------------------
step "Triggering publish-ppa workflow on ${PPA_REPO}"
echo "    tier_ref=${latest_tag}  series=${SERIES}  revision=${REVISION}  dry_run=${DRY_RUN}"

gh workflow run publish-ppa.yml \
    --repo "$PPA_REPO" \
    -f tier_ref="$latest_tag" \
    -f series="$SERIES" \
    -f revision="$REVISION" \
    -f dry_run="$DRY_RUN"

echo
echo "Workflow triggered."
echo "The build job runs automatically; then approve the 'ppa-publish' gate"
echo "in GitHub Actions to sign and upload."
echo
echo "  https://github.com/${PPA_REPO}/actions"
