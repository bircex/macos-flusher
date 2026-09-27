NAME := MacOS Flusher
EXEC := MacOSFlusher
ARCHS ?= $(shell uname -m)
VERSION ?=
BUNDLE := dist/$(NAME).app
PACKAGE := dist/MacOS-Flusher
INSTALL_DIR ?= /Applications

.PHONY: build bundle package run install uninstall clean icon

build:
	for arch in $(ARCHS); do swift build -c release --arch $$arch || exit 1; done

bundle: build
	rm -rf "$(BUNDLE)"
	mkdir -p "$(BUNDLE)/Contents/MacOS"
	lipo -create $(foreach arch,$(ARCHS),.build/$(arch)-apple-macosx/release/$(EXEC)) -output "$(BUNDLE)/Contents/MacOS/$(EXEC)"
	cp Info.plist "$(BUNDLE)/Contents/Info.plist"
ifneq ($(VERSION),)
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(VERSION)" -c "Set :CFBundleVersion $(VERSION)" "$(BUNDLE)/Contents/Info.plist"
endif
	mkdir -p "$(BUNDLE)/Contents/Resources"
	cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/AppIcon.icns"
	codesign --force --sign - "$(BUNDLE)"

package: bundle
	rm -rf "$(PACKAGE).zip" "$(PACKAGE).dmg" dist/dmg
	ditto -c -k --norsrc --noextattr --keepParent "$(BUNDLE)" "$(PACKAGE).zip"
	mkdir -p dist/dmg
	cp -R "$(BUNDLE)" dist/dmg/
	ln -s /Applications dist/dmg/Applications
	hdiutil create -volname "$(NAME)" -srcfolder dist/dmg -ov -format UDZO "$(PACKAGE).dmg"
	rm -rf dist/dmg
	cd dist && shasum -a 256 MacOS-Flusher.zip MacOS-Flusher.dmg > SHA256SUMS

run: bundle
	open "$(BUNDLE)"

install: bundle
	rm -rf "$(INSTALL_DIR)/$(NAME).app"
	cp -R "$(BUNDLE)" "$(INSTALL_DIR)/"

uninstall:
	rm -rf "$(INSTALL_DIR)/$(NAME).app"

clean:
	rm -rf .build dist

icon:
	swift Tools/make-icon.swift /tmp/MacOSFlusher-icon.png
	rm -rf /tmp/MacOSFlusher.iconset && mkdir -p /tmp/MacOSFlusher.iconset
	for n in 16 32 128 256 512; do \
		sips -z $$n $$n /tmp/MacOSFlusher-icon.png --out /tmp/MacOSFlusher.iconset/icon_$${n}x$${n}.png >/dev/null; \
		sips -z $$((n*2)) $$((n*2)) /tmp/MacOSFlusher-icon.png --out /tmp/MacOSFlusher.iconset/icon_$${n}x$${n}@2x.png >/dev/null; \
	done
	iconutil -c icns /tmp/MacOSFlusher.iconset -o Resources/AppIcon.icns
