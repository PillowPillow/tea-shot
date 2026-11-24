PROJECT    := TeaShot.xcodeproj
SCHEME     := TeaShot
DERIVED    := build
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) $(XCFLAGS)
APP        := $(DERIVED)/Build/Products/Release/TeaShot.app
ZIP        := $(DERIVED)/TeaShot.zip
DEST       := /Applications/TeaShot.app

.PHONY: build test run install uninstall zip clean

build:
	$(XCODEBUILD) -configuration Release -destination 'generic/platform=macOS' build

test:
	$(XCODEBUILD) -destination 'platform=macOS' test

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
