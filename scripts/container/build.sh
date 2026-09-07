#!/bin/sh
# Runs inside the build image. Fetches the Debian source packages for neatvnc
# and wayvnc, applies the patches under ../patches with quilt, and builds
# binary packages into the directory given as $1. wayvnc is built against the
# patched libneatvnc-dev, so neatvnc is built and installed first.
#
# SWAYVNC_BUILD names the build as <YYYYMMDD>-<N>, the tail of the release tag
# trixie-<YYYYMMDD>-<N>; each package's Debian version gets the suffix
# +swayvnc<YYYYMMDD>.<N>, so a later build always sorts newer for dpkg.
set -eu

out=${1:?output directory}
here=$(cd "$(dirname "$0")" && pwd)
build=${SWAYVNC_BUILD:-$(date -u +%Y%m%d)-0}
suffix="+swayvnc$(echo "$build" | tr '-' '.')"
export DEBFULLNAME=${DEBFULLNAME:-swayvnc}
export DEBEMAIL=${DEBEMAIL:-swayvnc@localhost}
export QUILT_PATCHES=debian/patches

mkdir -p "$out"

build() {
	pkg=$1
	mkdir -p "$here/src/$pkg"
	cd "$here/src/$pkg"
	apt-get source "$pkg"
	cd "$(find . -mindepth 1 -maxdepth 1 -type d -name "$pkg-*" | head -n 1)"
	for patch in "$here"/patches/"$pkg"/*.patch; do
		quilt import "$patch"
	done
	quilt push -a
	version="$(dpkg-parsechangelog -S Version)$suffix"
	dch --newversion "$version" --distribution unstable --force-distribution \
		"Apply the swayvnc density extension patches (build $build)."
	dpkg-buildpackage -us -uc -b
	cd ..
	cp ./*.deb "$out"/
}

build neatvnc
dpkg -i "$here"/src/neatvnc/libneatvnc0_*.deb "$here"/src/neatvnc/libneatvnc-dev_*.deb

build wayvnc

cd "$out"
sha256sum ./*.deb | sed 's#  \./#  #' > SHA256SUMS
cat SHA256SUMS
