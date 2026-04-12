#!/bin/sh
set -e

REPO="gas217/preview-md"
DEST="/Applications/PreviewMD.app"
BUNDLE_ID="com.previewmd.PreviewMD.QuickLook"
PLIST_NAME="com.previewmd.updater.plist"
PLIST_SRC="$DEST/Contents/Resources/$PLIST_NAME"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "Installing PreviewMD..."
rm -rf "$DEST"
curl -sL "https://github.com/$REPO/releases/latest/download/PreviewMD.tar.gz" | tar xz -C /Applications
xattr -cr "$DEST" 2>/dev/null || true

# Register and enable the Quick Look extension
open "$DEST"
qlmanage -r >/dev/null 2>&1 || true
pluginkit -e use -i "$BUNDLE_ID" 2>/dev/null || true

# Install auto-updater LaunchAgent (checks every 5 min)
if [ -f "$PLIST_SRC" ]; then
    mkdir -p "$HOME/Library/LaunchAgents"
    launchctl unload "$PLIST_DST" 2>/dev/null || true
    cp "$PLIST_SRC" "$PLIST_DST"
    launchctl load "$PLIST_DST"
    echo "Auto-updater installed (checks every 5 min)"
fi

echo "Installed to $DEST"
echo "Preview any .md file in Finder with Space (Option+Space for full-screen)"
