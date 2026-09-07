# check=skip=InvalidDefaultArgInFrom
ARG BASE_IMAGE=debian:trixie
FROM ${BASE_IMAGE} AS build

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The Debian source packages and their build dependencies; deb-src is off in
# the image's sources.
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential ca-certificates devscripts quilt && \
    apt-get build-dep -y neatvnc wayvnc

WORKDIR /build
COPY patches /build/patches
COPY scripts/container/build.sh /build/build.sh

ARG SWAYVNC_SUFFIX=+swayvnc
RUN SWAYVNC_SUFFIX="${SWAYVNC_SUFFIX}" ./build.sh /out

FROM scratch
COPY --from=build /out /
