#!/bin/sh
set -e

REPO="gas217/preview-md"
DEST="/Applications/PreviewMD.app"
BUNDLE_ID="com.previewmd.PreviewMD.QuickLook"

echo "Installing PreviewMD..."
rm -rf "$DEST"
curl -sL "https://github.com/$REPO/releases/latest/download/PreviewMD.tar.gz" | tar xz -C /Applications
xattr -cr "$DEST" 2>/dev/null || true

# Register and enable the Quick Look extension
open "$DEST"
qlmanage -r >/dev/null 2>&1 || true
pluginkit -e use -i "$BUNDLE_ID" 2>/dev/null || true

echo "Installed to $DEST"
echo "Preview any .md file in Finder with Space (Option+Space for full-screen)"
