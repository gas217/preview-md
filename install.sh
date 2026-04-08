#!/bin/sh
set -e

REPO="gas217/preview-md"
DEST="/Applications/PreviewMD.app"

echo "Installing PreviewMD..."
rm -rf "$DEST"
curl -sL "https://github.com/$REPO/releases/latest/download/PreviewMD.tar.gz" | tar xz -C /Applications
qlmanage -r >/dev/null 2>&1 || true
echo "Installed to $DEST"
echo "Enable in System Settings > General > Login Items & Extensions > Extensions > Quick Look"
