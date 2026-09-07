#!/usr/bin/env bash
# Build the patched neatvnc and wayvnc .debs for Debian trixie on amd64 and
# arm64 with Docker buildx, into output/trixie/<arch>/.
#
#   ./scripts/build-debs.sh [arch ...]     default: arm64 amd64
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
arches=("$@")
[[ ${#arches[@]} -gt 0 ]] || arches=(arm64 amd64)

for arch in "${arches[@]}"; do
	dest="${here}/output/trixie/${arch}"
	rm -rf "${dest}"
	mkdir -p "${dest}"
	docker buildx build \
		--platform "linux/${arch}" \
		--file "${here}/docker/Dockerfile" \
		--output "type=local,dest=${dest}" \
		"${here}"
	echo "== ${arch}"
	cat "${dest}/SHA256SUMS"
done
