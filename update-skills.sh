#!/bin/bash
# Regenerate the skills/ snapshot from an Xcode install.
#
# Usage: ./update-skills.sh [/path/to/Xcode.app]
#   Defaults to the active Xcode (xcode-select -p).
#
# Requirements: the target Xcode must be RUNNING with its license accepted,
# or the `xcrun agent skills export` step will hang on the license dialog.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

if [[ $# -ge 1 ]]; then
  XCODE_APP="${1%/}"
else
  XCODE_APP="$(dirname "$(dirname "$(xcode-select -p)")")"
fi

DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
[[ -d "$DEVELOPER_DIR" ]] || { echo "error: $XCODE_APP does not look like an Xcode app bundle" >&2; exit 1; }
export DEVELOPER_DIR

BUILD="$(/usr/libexec/PlistBuddy -c 'Print :ProductBuildVersion' "$XCODE_APP/Contents/version.plist")"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$XCODE_APP/Contents/version.plist")"
echo "Snapshotting skills from Xcode $VERSION ($BUILD) at $XCODE_APP"

if ! pgrep -qf "$XCODE_APP/Contents/MacOS/Xcode"; then
  echo "warning: this Xcode does not appear to be running; the export step will hang until it is" >&2
fi

# 1. Globally available skills, via the supported export command.
#    --output-dir must be absolute: relative paths resolve against Xcode's own cwd.
xcrun agent skills export --output-dir "$SKILLS_DIR" --replace-existing

# 2. Translation skills: not globally available (Xcode injects them into its
#    localization agent flow), but they sit on disk in the app bundle.
XCSTRINGS_SKILLS="$XCODE_APP/Contents/PlugIns/IDEXCStringsSupport.framework/Versions/A/Resources/Skills"
for skill in translation translation-coordinator; do
  if [[ -d "$XCSTRINGS_SKILLS/$skill" ]]; then
    rm -rf "$SKILLS_DIR/$skill"
    cp -R "$XCSTRINGS_SKILLS/$skill" "$SKILLS_DIR/$skill"
    echo "  ✓ $skill (copied from IDEXCStringsSupport)"
  else
    echo "warning: $skill not found in IDEXCStringsSupport — moved or removed in this build?" >&2
  fi
done

# 3. ios-dynamic-text: embedded as a string constant in the IDEAXSpecialist binary.
AX_BINARY="$XCODE_APP/Contents/PlugIns/IDEAXSpecialist.framework/Versions/A/IDEAXSpecialist"
python3 - "$AX_BINARY" "$SKILLS_DIR" <<'PYEOF'
import sys, os

binary_path, skills_dir = sys.argv[1], sys.argv[2]
data = open(binary_path, "rb").read()

marker = b"name: ios-dynamic-text"
idx = data.find(marker)
if idx == -1:
    sys.exit("warning: ios-dynamic-text marker not found in IDEAXSpecialist — moved or removed in this build?")

start = data.rfind(b"\x00", 0, idx) + 1
end = data.find(b"\x00", idx)
content = data[start:end].decode("utf-8")

if not (content.startswith("---") and content.rstrip().count("\n") > 10):
    sys.exit("error: extracted ios-dynamic-text content looks malformed; binary layout may have changed")

out_dir = os.path.join(skills_dir, "ios-dynamic-text")
os.makedirs(out_dir, exist_ok=True)
with open(os.path.join(out_dir, "SKILL.md"), "w") as f:
    f.write(content)
print(f"  ✓ ios-dynamic-text (extracted {len(content)} bytes from IDEAXSpecialist binary)")
PYEOF

echo
echo "Done. Review with: git -C \"$REPO_DIR\" status"
echo "Then:             git -C \"$REPO_DIR\" add -A && git -C \"$REPO_DIR\" commit -m \"Xcode $VERSION ($BUILD)\" && git -C \"$REPO_DIR\" tag $BUILD"
