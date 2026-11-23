#!/bin/bash
# Builds ~/Applications/AC Join Link.app, which passes online-join links to Content Manager.
set -euo pipefail
BOTTLE=Steam CX=/Applications/CrossOver.app
while [ $# -gt 0 ]; do case "$1" in
  --bottle) BOTTLE=$2; shift 2;; --crossover) CX=$2; shift 2;;
  *) echo "Unknown option: $1" >&2; exit 2;; esac; done
WINE="$CX/Contents/SharedSupport/CrossOver/bin/wine"
[ -x "$WINE" ] || { echo "CrossOver not found at $CX" >&2; exit 1; }
case "$WINE$BOTTLE" in *[\"\\]*) echo "Quotes and backslashes are not supported in paths" >&2; exit 1;; esac
APP="$HOME/Applications/AC Join Link.app"
[ ! -e "$APP" ] || { echo "$APP already exists" >&2; exit 1; }
mkdir -p "$HOME/Applications"
TMP=$(mktemp -d); trap 'rm -rf "${TMP:?}"' EXIT
cat > "$TMP/join.applescript" <<EOF
on open location u
	if u does not start with "acmanager://race/online/join?" then
		display dialog "This helper only opens Assetto Corsa online join links." buttons {"OK"} default button 1
		return
	end if
	do shell script quoted form of "$WINE" & " --bottle " & quoted form of "$BOTTLE" & " 'C:\\\\Content Manager\\\\Content Manager Local Safe.exe' " & quoted form of u & " > /dev/null 2>&1 &"
end open location
EOF
osacompile -o "$APP" "$TMP/join.applescript"
P="$APP/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string local.ac-join-link "$P"
plutil -insert CFBundleURLTypes -json '[{"CFBundleURLName":"Assetto Corsa join link","CFBundleURLSchemes":["acmanager"]}]' "$P"
codesign --force --sign - "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
echo "Created $APP. It has no window; it only reacts to links."
