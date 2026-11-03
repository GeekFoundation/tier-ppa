#!/usr/bin/env bash
# Generate debian/changelog for one PPA upload.
#
# Usage: make-changelog.sh <upstream-version> <series> <revision> <src-dir>
#   upstream-version  clean Tier version, e.g. 0.5.0 (no leading v)
#   series            Ubuntu series codename, e.g. noble, jammy
#   revision          packaging revision N; bump to re-upload the SAME upstream
#                     version for the SAME series (Launchpad rejects a re-upload
#                     of an identical version)
#   src-dir           upstream checkout that debian/ was overlaid onto
#
# Package version is <upstream>~<series><revision>, e.g. 0.5.0~noble1. The tilde
# sorts BELOW the plain upstream version, which is the convention for a
# distro-series rebuild and keeps ordering sane across series.
#
# Maintainer identity comes from DEBFULLNAME/DEBEMAIL (set by the workflow).
set -euo pipefail

UPVER="$1"
SERIES="$2"
REV="$3"
SRC="$4"

PKGVER="${UPVER}~${SERIES}${REV}"
NAME="${DEBFULLNAME:-Geek Foundation}"
EMAIL="${DEBEMAIL:-admin@geek.foundation}"

cat > "${SRC}/debian/changelog" <<EOF
tierd (${PKGVER}) ${SERIES}; urgency=medium

  * Tier release ${UPVER}, packaged for the Geek Foundation PPA.

 -- ${NAME} <${EMAIL}>  $(date -R)
EOF

echo "wrote ${SRC}/debian/changelog (${PKGVER})"
