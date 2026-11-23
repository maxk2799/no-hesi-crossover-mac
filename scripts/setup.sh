#!/bin/bash
# Applies the CrossOver fixes described in README.md. Never overwrites existing files.
set -euo pipefail
BOTTLE=Steam CX=/Applications/CrossOver.app CX25=
while [ $# -gt 0 ]; do case "$1" in
  --bottle) BOTTLE=$2; shift 2;; --crossover) CX=$2; shift 2;; --crossover25) CX25=$2; shift 2;;
  *) echo "Unknown option: $1" >&2; exit 2;; esac; done
die() { echo "Error: $*" >&2; exit 1; }
HERE=$(cd "$(dirname "$0")" && pwd)
WINE="$CX/Contents/SharedSupport/CrossOver/bin/wine"
BDIR="$HOME/Library/Application Support/CrossOver/Bottles/$BOTTLE"
APPS="$BDIR/drive_c/Program Files (x86)/Steam/steamapps/common"
GAME="$APPS/assettocorsa"
DX="$APPS/Steamworks Shared/_CommonRedist/DirectX/Jun2010"
DBG="$CX25/Contents/SharedSupport/CrossOver/lib/wine/x86_64-windows/dbghelp.dll"
[ -x "$WINE" ] || die "CrossOver not found at $CX"
[ -f "$GAME/acs.exe" ] || die "Assetto Corsa not found in bottle $BOTTLE"
[ -f "$GAME/dwrite.dll" ] || die "Install CSP first (dwrite.dll is missing)"
[ -n "$CX25" ] && [ -f "$DBG" ] || die "Pass --crossover25 with an unzipped CrossOver 25.1.1"
if pgrep -f '^C:.*acs\.exe' >/dev/null; then die "Close Assetto Corsa first"; fi
for n in d3dx11_43 D3DCompiler_43; do [ -f "$DX/Jun2010_${n}_x64.cab" ] || die "Missing $DX/Jun2010_${n}_x64.cab (let Steam install DirectX)"; done

TMP=$(mktemp -d); trap 'rm -rf "${TMP:?}"' EXIT
put() { if [ -e "$2" ]; then echo "Keeping existing $(basename "$2")"; else cp "$1" "$2"; echo "Added $(basename "$2")"; fi; }
for n in d3dx11_43 D3DCompiler_43; do
  bsdtar -xf "$DX/Jun2010_${n}_x64.cab" -C "$TMP"
  put "$TMP/$n.dll" "$GAME/$(echo "$n" | tr '[:upper:]' '[:lower:]').dll"
done
[ -e "$GAME/dbghelp.dll" ] && echo "Keeping existing dbghelp.dll" || python3 "$HERE/patch-dbghelp.py" "$DBG" "$GAME/dbghelp.dll"

FONTS="$GAME/content/fonts/system"; SRC=/System/Library/Fonts/Supplemental; mkdir -p "$FONTS"
put "$SRC/Arial.ttf" "$FONTS/segoeui.ttf"; put "$SRC/Arial Bold.ttf" "$FONTS/segoeuib.ttf"
put "$SRC/Arial Italic.ttf" "$FONTS/segoeuii.ttf"; put "$SRC/Arial Bold Italic.ttf" "$FONTS/segoeuiz.ttf"

USERDOCS="$BDIR/drive_c/users/crossover/Documents/Assetto Corsa"
CFG="$USERDOCS/cfg/extension"; mkdir -p "$CFG" "$USERDOCS/logs"
if [ -e "$CFG/general.ini" ]; then echo "general.ini exists: add CACHE_ACS=0 under [OPTIMIZATIONS] yourself if CSP reports cache errors"
else printf '[OPTIMIZATIONS]\nCACHE_ACS=0\n' > "$CFG/general.ini"; fi

KEY='HKCU\Software\Wine\AppDefaults\acs.exe\DllOverrides'
for n in dwrite d3dx11_43 d3dcompiler_43 dbghelp; do
  "$WINE" --bottle "$BOTTLE" --wait-children reg add "$KEY" /v "$n" /t REG_SZ /d native,builtin /f >/dev/null
done
"$WINE" --bottle "$BOTTLE" --wait-children reg add 'HKCU\Software\Microsoft\Avalon.Graphics' /v DisableHWAcceleration /t REG_DWORD /d 1 /f >/dev/null
echo "Done. Start Content Manager and test a stock car offline."
