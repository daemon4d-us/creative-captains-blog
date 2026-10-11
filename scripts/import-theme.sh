#!/usr/bin/env bash
# Runs on your laptop. Downloads the latest tagged release of an official Ghost theme into
# themes/<dest> so you can customise it in this repo. The deploy-theme workflow uploads every
# themes/*/ that has a package.json.
#
# Ghost reserves the names "casper" and "source" for its bundled themes, so the copy is renamed
# (package.json "name" and directory) to <dest>, default "creative-captains".
#
# Usage: scripts/import-theme.sh [source|casper] [dest]
set -euo pipefail

THEME="${1:-source}"
DEST_NAME="${2:-creative-captains}"
case "$THEME" in
  source) REPO="TryGhost/Source" ;;
  casper) REPO="TryGhost/Casper" ;;
  *) echo "unknown theme: $THEME (use source or casper)" >&2; exit 1 ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/themes/$DEST_NAME"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -e "$DEST" ]]; then
  echo "$DEST already exists; remove it first if you want a fresh copy" >&2
  exit 1
fi

# Releases carry no zip assets, but the tagged source tree includes the built CSS/JS.
TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | jq -r .tag_name)"
echo "Downloading $REPO $TAG..."
curl -fsSL -o "$TMP/theme.zip" "https://github.com/$REPO/archive/refs/tags/$TAG.zip"
unzip -q "$TMP/theme.zip" -d "$TMP/unzipped"

# The archive contains a single top-level folder, e.g. Source-1.7.6.
SRC="$(find "$TMP/unzipped" -mindepth 1 -maxdepth 1 -type d | head -n1)"
mkdir -p "$ROOT/themes"
mv "$SRC" "$DEST"
rm -f "$DEST/renovate.json"

jq --arg n "$DEST_NAME" '.name = $n' "$DEST/package.json" > "$DEST/package.json.tmp" \
  && mv "$DEST/package.json.tmp" "$DEST/package.json"

echo "Imported $REPO $TAG into themes/$DEST_NAME as theme '$DEST_NAME'"
