# swayvnc

wayvnc for a sway desktop behind the remotex gateway, as patches on the Debian
source packages of neatvnc 0.9.1 and wayvnc 0.9.1.

`patches/neatvnc/` adds three application hooks to the library: the client's
`SetEncodings` list as sent, an empty one included, a handler for client message
types the library does not dispatch, and a call to write one server message to
one client.

`patches/wayvnc/` uses them for a private density extension. A client that lists
the pseudo-encoding `0x53564e43` (`SVNC`) receives an `OutputScale` message,
type `0xe0`, whenever the captured output's scale or size changes:

| Offset | Type | Field |
|---|---|---|
| 0 | U8 | `0xe0` |
| 1 | U8 | padding |
| 2 | U16 | width in pixels |
| 4 | U16 | height in pixels |
| 6 | U32 | scale, 16.16 unsigned fixed point |

The first one is the answer to `SetEncodings`, which is how support is
announced. The client may send a `ClientDensity` message with the same type:
`0xe0`, three padding bytes, then the density it wants the output drawn at as a
16.16 scale. wayvnc sets the captured output's scale to it through
wlr-output-management under the same rules as a client's `SetDesktopSize` — a
headless output, resizing enabled, and the client owns the layout or nobody
does yet — and answers every declaration with an `OutputScale`: after the
compositor has applied the change, or at once with the scale as it is when
nothing is to be changed or nothing can be. A configuration the compositor
accepts without changing the head's scale is answered as well: the `succeeded`
is followed by one round trip, and the scale is reported as it is when no head
change has arrived by then. A client that declares its density before asking
for a size therefore gets the desktop drawn once, in the right pixels.

The scale is the compositor's exact value from wlr-output-management, with
`wl_output.scale` as the fallback.

`scripts/build-debs.sh` builds both packages for Debian trixie on arm64 and
amd64 in Docker, from the Debian source packages with the patches applied by
quilt, and writes the `.deb` files and a `SHA256SUMS` under `output/trixie/<arch>/`.

Releases are made by the **Build and release packages** workflow, run by hand.
It tags the release `trixie-<YYYYMMDD>-<N>` — the distribution and the build,
never a library version — and the packages inside keep Debian's versions with a
`+swayvnc<YYYYMMDD>.<N>` suffix, so a later build always sorts newer for dpkg. On
a host, install `libneatvnc0` and `wayvnc` for its architecture from the release
with `dpkg -i` and hold them so an upgrade does not put the stock packages back;
the `workstation-ansible` sway role does exactly that by checksum.
