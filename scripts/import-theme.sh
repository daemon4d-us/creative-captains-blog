#!/usr/bin/env bash
# Runs on your laptop. Downloads the latest release of an official Ghost theme into themes/<name>
# so you can customise it in this repo. The deploy-theme workflow uploads every themes/*/ that
# has a package.json.
#
# Usage: scripts/import-theme.sh [source|casper]
set -euo pipefail

THEME="${1:-source}"
case "$THEME" in
  source) REPO="TryGhost/Source" ;;
  casper) REPO="TryGhost/Casper" ;;
  *) echo "unknown theme: $THEME (use source or casper)" >&2; exit 1 ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/themes/$THEME"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -e "$DEST" ]]; then
  echo "$DEST already exists; remove it first if you want a fresh copy" >&2
  exit 1
fi

echo "Downloading latest $REPO release..."
curl -fsSL -o "$TMP/theme.zip" "https://github.com/$REPO/releases/latest/download/$THEME.zip"
unzip -q "$TMP/theme.zip" -d "$TMP/unzipped"

# Release zips contain a single top-level folder named after the theme.
SRC="$(find "$TMP/unzipped" -mindepth 1 -maxdepth 1 -type d | head -n1)"
mkdir -p "$ROOT/themes"
mv "$SRC" "$DEST"

echo "Imported $REPO into themes/$THEME ($(jq -r .version "$DEST/package.json"))"
echo "Set 'name' in themes/$THEME/package.json if you want it to show under a different name in Ghost Admin."
