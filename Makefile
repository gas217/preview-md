.PHONY: build test deploy release notarize clean vendor-mermaid

MERMAID_VERSION = 11.14.0
MERMAID_URL = https://unpkg.com/mermaid@$(MERMAID_VERSION)/dist/mermaid.min.js
MERMAID_DST = Resources/mermaid.min.js
MERMAID_PROV = Resources/mermaid-source.txt

DERIVED = build
APP = $(DERIVED)/Build/Products/Release/PreviewMD.app
EXT = $(APP)/Contents/PlugIns/PreviewMDQuickLook.appex
THUMB = $(APP)/Contents/PlugIns/PreviewMDThumbnail.appex
SIGN_ID = Developer ID Application: AZAT SHAMILEVICH GAYNUTDINOV (LY8G872X5U)
BUNDLE_ID = com.previewmd.PreviewMD.QuickLook
VERSION = $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" App/Info.plist 2>/dev/null || echo "1.0.0")

build:
	@xcodegen generate
	@xcodebuild -project PreviewMD.xcodeproj -scheme PreviewMD \
		-configuration Release -derivedDataPath $(DERIVED) build \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
		2>&1 | tail -1

test:
	@xcodegen generate
	@xcodebuild -project PreviewMD.xcodeproj -scheme PreviewMD \
		-configuration Debug -derivedDataPath $(DERIVED) build-for-testing \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
		2>&1 | tail -1
	@xcrun xctest $(DERIVED)/Build/Products/Debug/PreviewMDTests.xctest

sign: build
	@echo "==> Bundling updater scripts..."
	@cp scripts/check-update.sh "$(APP)/Contents/Resources/"
	@cp scripts/com.previewmd.updater.plist "$(APP)/Contents/Resources/"
	@chmod +x "$(APP)/Contents/Resources/check-update.sh"
	@echo "==> Signing..."
	@codesign --force --options runtime --sign "$(SIGN_ID)" \
		--entitlements Extension/PreviewMDQuickLook.entitlements "$(EXT)"
	@codesign --force --options runtime --sign "$(SIGN_ID)" \
		--entitlements Thumbnail/PreviewMDThumbnail.entitlements "$(THUMB)"
	@codesign --force --options runtime --sign "$(SIGN_ID)" \
		--entitlements App/PreviewMD.entitlements "$(APP)"

deploy: sign
	@echo "==> Installing to /Applications..."
	@rm -rf /Applications/PreviewMD.app
	@cp -R "$(APP)" /Applications/PreviewMD.app
	@xattr -cr /Applications/PreviewMD.app 2>/dev/null || true
	@qlmanage -r 2>/dev/null || true
	@pluginkit -e use -i "$(BUNDLE_ID)" 2>/dev/null || true
	@echo "==> Installing auto-updater LaunchAgent..."
	@mkdir -p ~/Library/LaunchAgents
	@cp /Applications/PreviewMD.app/Contents/Resources/com.previewmd.updater.plist ~/Library/LaunchAgents/
	@launchctl unload ~/Library/LaunchAgents/com.previewmd.updater.plist 2>/dev/null || true
	@launchctl load ~/Library/LaunchAgents/com.previewmd.updater.plist
	@open /Applications/PreviewMD.app
	@echo "==> Deployed (auto-updater active, checking every 5 min)."

notarize: sign
	@echo "==> Creating zip for notarization..."
	@ditto -c -k --keepParent "$(APP)" /tmp/PreviewMD-notarize.zip
	@echo "==> Submitting to Apple..."
	@xcrun notarytool submit /tmp/PreviewMD-notarize.zip \
		--keychain-profile "notarytool-password" --wait
	@echo "==> Stapling..."
	@xcrun stapler staple "$(APP)"

release: notarize
	@echo "==> Packaging v$(VERSION)..."
	@tar -czf /tmp/PreviewMD.tar.gz -C $(DERIVED)/Build/Products/Release PreviewMD.app
	@gh release create "v$(VERSION)" /tmp/PreviewMD.tar.gz \
		--title "PreviewMD v$(VERSION)" --notes "Quick Look previews for Markdown files"
	@echo "==> Released v$(VERSION)"

vendor-mermaid:
	@echo "==> Fetching mermaid@$(MERMAID_VERSION)..."
	@curl -fsSL "$(MERMAID_URL)" -o /tmp/mermaid.raw.js
	@UPSTREAM_SHA=$$(shasum -a 256 /tmp/mermaid.raw.js | awk '{print $$1}'); \
	 echo "    upstream sha256: $$UPSTREAM_SHA"; \
	 COUNT=$$(grep -c 'Function("return this")' /tmp/mermaid.raw.js); \
	 if [ "$$COUNT" -lt 1 ]; then \
	   echo "ERROR: no Function(\"return this\") calls found — did upstream fix it? Check manually."; \
	   exit 1; \
	 fi; \
	 echo "    found $$COUNT Function(\"return this\") occurrences"; \
	 sed 's/Function("return this")()/globalThis/g; s/Function("return this")/(function(){return globalThis})/g' /tmp/mermaid.raw.js > "$(MERMAID_DST)"; \
	 REMAIN=$$(grep -c 'Function("return this")' "$(MERMAID_DST)" || true); \
	 if [ "$$REMAIN" != "0" ]; then \
	   echo "ERROR: $$REMAIN Function(\"return this\") calls remain after patch"; \
	   exit 1; \
	 fi; \
	 PATCHED_SHA=$$(shasum -a 256 "$(MERMAID_DST)" | awk '{print $$1}'); \
	 printf "source: %s\nupstream_sha256: %s\npatched_sha256: %s\npatch: sed 's/Function(\"return this\")()/globalThis/g; s/Function(\"return this\")/(function(){return globalThis})/g'\n" \
	   "$(MERMAID_URL)" "$$UPSTREAM_SHA" "$$PATCHED_SHA" > "$(MERMAID_PROV)"
	@rm -f /tmp/mermaid.raw.js
	@echo "==> Wrote $(MERMAID_DST) ($$(wc -c < $(MERMAID_DST) | tr -d ' ') bytes) + $(MERMAID_PROV)"

clean:
	@rm -rf $(DERIVED)
	@echo "Cleaned."
