.PHONY: build test deploy clean

DERIVED = build
APP = $(DERIVED)/Build/Products/Release/PreviewMD.app
EXT = $(APP)/Contents/PlugIns/PreviewMDQuickLook.appex
SIGN_ID = Developer ID Application: AZAT SHAMILEVICH GAYNUTDINOV (LY8G872X5U)

build:
	@xcodegen generate
	@xcodebuild -project PreviewMD.xcodeproj -scheme PreviewMD \
		-configuration Release -derivedDataPath $(DERIVED) build \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
		2>&1 | tail -1

test: build
	@xcodebuild -project PreviewMD.xcodeproj -scheme PreviewMD \
		-configuration Debug -derivedDataPath $(DERIVED) build-for-testing \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
		2>&1 | tail -1
	@xcrun xctest $(DERIVED)/Build/Products/Debug/PreviewMDTests.xctest

deploy: build
	@echo "==> Signing..."
	@codesign --force --sign "$(SIGN_ID)" \
		--entitlements Extension/PreviewMDQuickLook.entitlements "$(EXT)"
	@codesign --force --sign "$(SIGN_ID)" \
		--entitlements App/PreviewMD.entitlements "$(APP)"
	@echo "==> Installing to /Applications..."
	@rm -rf /Applications/PreviewMD.app
	@cp -R "$(APP)" /Applications/PreviewMD.app
	@qlmanage -r 2>/dev/null || true
	@echo "==> Deployed. Enable in System Settings > Extensions > Quick Look."

clean:
	@rm -rf $(DERIVED)
	@echo "Cleaned."
