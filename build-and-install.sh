#!/bin/sh
# Build neatvnc and wayvnc from the Debian source packages with the patches
# under patches/ applied, and install the results. Runs on the sway host.
#
#   ./build-and-install.sh [workdir]
#
# The packages get a local version suffix (SWAYVNC_SUFFIX, default +swayvnc1)
# and are put on hold so an apt upgrade does not put the stock ones back.
# wayvnc is built against the patched libneatvnc-dev, so neatvnc is built and
# installed first. Needs deb-src entries, quilt, devscripts and the two
# packages' build dependencies:
#
#   sudo apt-get build-dep neatvnc wayvnc && sudo apt-get install quilt devscripts
set -eu

here=$(cd "$(dirname "$0")" && pwd)
work=${1:-$here/build}
suffix=${SWAYVNC_SUFFIX:-+swayvnc1}
export DEBFULLNAME=${DEBFULLNAME:-swayvnc}
export DEBEMAIL=${DEBEMAIL:-swayvnc@localhost}
export QUILT_PATCHES=debian/patches

mkdir -p "$work"

build() {
	pkg=$1
	cd "$work"
	rm -rf "$pkg"-*/ "$pkg"_*
	apt-get source "$pkg"
	dir=$(find . -mindepth 1 -maxdepth 1 -type d -name "$pkg-*" | head -n 1)
	cd "$dir"
	for patch in "$here"/patches/"$pkg"/*.patch; do
		quilt import "$patch"
	done
	quilt push -a
	dch --local "$suffix" --distribution unstable \
		"Apply the swayvnc density extension patches."
	dpkg-buildpackage -us -uc -b
	cd "$work"
}

install_debs() {
	# shellcheck disable=SC2086
	sudo dpkg -i $1
	# shellcheck disable=SC2086
	sudo apt-mark hold $2
}

build neatvnc
install_debs "$(ls "$work"/libneatvnc0_*"$suffix"_*.deb "$work"/libneatvnc-dev_*"$suffix"_*.deb)" \
	"libneatvnc0 libneatvnc-dev"

build wayvnc
install_debs "$(ls "$work"/wayvnc_*"$suffix"_*.deb)" wayvnc

echo "installed:"
dpkg-query -W -f '${Package} ${Version}\n' libneatvnc0 libneatvnc-dev wayvnc
