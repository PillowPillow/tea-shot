PROJECT    := TeaShot.xcodeproj
SCHEME     := TeaShot
DERIVED    := build
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) $(XCFLAGS)
APP        := $(DERIVED)/Build/Products/Release/TeaShot.app
ZIP        := $(DERIVED)/TeaShot.zip
DEST       := /Applications/TeaShot.app

SOURCES    := TeaShot TeaShotTests Tools docs/brand

.PHONY: build test lint format run install uninstall zip clean

build:
	$(XCODEBUILD) -configuration Release -destination 'generic/platform=macOS' build

test:
	$(XCODEBUILD) -destination 'platform=macOS' test

lint:
	swift format lint --strict --recursive $(SOURCES)

format:
	swift format format --in-place --recursive $(SOURCES)

run: build
	open $(APP)

install: build
	-pkill -x TeaShot
	rm -rf $(DEST)
	ditto $(APP) $(DEST)
	open $(DEST)

uninstall:
	-pkill -x TeaShot
	rm -rf $(DEST)

zip: build
	rm -f $(ZIP)
	ditto -c -k --keepParent $(APP) $(ZIP)

clean:
	rm -rf $(DERIVED)
