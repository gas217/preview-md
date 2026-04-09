.PHONY: build test deploy release notarize clean

DERIVED = build
APP = $(DERIVED)/Build/Products/Release/PreviewMD.app
EXT = $(APP)/Contents/PlugIns/PreviewMDQuickLook.appex
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
	@echo "==> Signing..."
	@codesign --force --options runtime --sign "$(SIGN_ID)" \
		--entitlements Extension/PreviewMDQuickLook.entitlements "$(EXT)"
	@codesign --force --options runtime --sign "$(SIGN_ID)" \
		--entitlements App/PreviewMD.entitlements "$(APP)"

deploy: sign
	@echo "==> Installing to /Applications..."
	@rm -rf /Applications/PreviewMD.app
	@cp -R "$(APP)" /Applications/PreviewMD.app
	@xattr -cr /Applications/PreviewMD.app 2>/dev/null || true
	@qlmanage -r 2>/dev/null || true
	@pluginkit -e use -i "$(BUNDLE_ID)" 2>/dev/null || true
	@open /Applications/PreviewMD.app
	@echo "==> Deployed."

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

clean:
	@rm -rf $(DERIVED)
	@echo "Cleaned."
