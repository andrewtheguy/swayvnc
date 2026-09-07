# swayvnc

wayvnc for a sway desktop behind the remotex gateway, as patches on the Debian
source packages of neatvnc 0.9.1 and wayvnc 0.9.1.

`patches/neatvnc/` adds three application hooks to the library: the client's
`SetEncodings` list as sent, a handler for client message types the library does
not dispatch, and a call to write one server message to one client.

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
`0xe0`, three padding bytes, then its density as a 16.16 scale. This version
records and logs it.

The scale is the compositor's exact value from wlr-output-management, with
`wl_output.scale` as the fallback.

`build-and-install.sh` fetches the Debian sources, applies the patches with
quilt, builds both packages with a `+swayvnc1` version suffix, installs them and
puts them on hold.
