#!/bin/sh
# PreviewMD auto-updater — ETag-based change detection.
# Runs via LaunchAgent every 5 minutes. Costs one HEAD request
# when no update is available (~50ms). Downloads + installs only
# when the release asset has changed.
set -e

REPO="gas217/preview-md"
ASSET_URL="https://github.com/$REPO/releases/latest/download/PreviewMD.tar.gz"
ETAG_FILE="$HOME/.previewmd-etag"
DEST="/Applications/PreviewMD.app"
BUNDLE_ID="com.previewmd.PreviewMD.QuickLook"

# Fetch remote ETag via HEAD request
remote_etag=$(curl -sI -L "$ASSET_URL" 2>/dev/null | grep -i '^etag:' | tail -1 | tr -d '\r' | awk '{print $2}')

if [ -z "$remote_etag" ]; then
    # Network error or no ETag header — skip silently
    exit 0
fi

# Compare against stored ETag
if [ -f "$ETAG_FILE" ]; then
    stored_etag=$(cat "$ETAG_FILE")
    if [ "$remote_etag" = "$stored_etag" ]; then
        exit 0
    fi
fi

# ETag differs (or no stored ETag) — download and install
rm -rf "$DEST"
curl -sL "$ASSET_URL" | tar xz -C /Applications
xattr -cr "$DEST" 2>/dev/null || true

# Reset Quick Look to pick up the new extension
qlmanage -r >/dev/null 2>&1 || true
pluginkit -e use -i "$BUNDLE_ID" 2>/dev/null || true

# Store new ETag
echo "$remote_etag" > "$ETAG_FILE"
