#!/bin/sh
# Uninstall PreviewMD and clean up all artifacts.
set -e

echo "Uninstalling PreviewMD..."

# Stop and remove auto-updater
launchctl unload "$HOME/Library/LaunchAgents/com.previewmd.updater.plist" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.previewmd.updater.plist"
rm -f "$HOME/.previewmd-etag"

# Remove the app (this also removes the QL extension inside it)
rm -rf /Applications/PreviewMD.app

# Reset Quick Look so it stops looking for our extension
qlmanage -r >/dev/null 2>&1 || true

echo "PreviewMD uninstalled."
echo "Quick Look extension, auto-updater, and all config removed."
