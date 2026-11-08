#!/bin/sh
# Builds the .pk3 (a plain zip of the mod files).
set -e
cd "$(dirname "$0")"
VERSION=$(sed -n 's/.*StaticText "v\([0-9.]*\)".*/\1/p' menudef.txt | head -1)
OUT="HDTacticalHUD-v$VERSION.pk3"
rm -f "$OUT"
zip -r -X "$OUT" zscript.zs zscript mapinfo.txt cvarinfo.txt keyconf.txt \
	menudef.txt language.hdrn language.bcs gldefs.txt bcsblur.fp graphics >/dev/null
echo "$OUT"
