#!/bin/sh
# Store notarization credentials in the macOS keychain.
# Run once interactively: sh scripts/setup-notarytool.sh
# After this, `make release` can notarize without prompts.

APPLE_ID="YOUR_APPLE_ID@email.com"
TEAM_ID="LY8G872X5U"
APP_SPECIFIC_PASSWORD="YOUR_APP_SPECIFIC_PASSWORD"
PROFILE_NAME="notarytool-password"

# Generate app-specific password at:
# https://appleid.apple.com → Sign-In and Security → App-Specific Passwords

xcrun notarytool store-credentials "$PROFILE_NAME" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD"

echo "Credentials stored as '$PROFILE_NAME'. Run 'make release' to notarize and publish."
