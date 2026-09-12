NAME := MacOS Flusher
EXEC := MacOSFlusher
BIN := .build/release/$(EXEC)
BUNDLE := dist/$(NAME).app
INSTALL_DIR ?= /Applications

.PHONY: build bundle run install uninstall clean icon

build:
	swift build -c release

bundle: build
	rm -rf "$(BUNDLE)"
	mkdir -p "$(BUNDLE)/Contents/MacOS"
	cp "$(BIN)" "$(BUNDLE)/Contents/MacOS/$(EXEC)"
	cp Info.plist "$(BUNDLE)/Contents/Info.plist"
	mkdir -p "$(BUNDLE)/Contents/Resources"
	cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/AppIcon.icns"
	codesign --force --sign - "$(BUNDLE)"

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
