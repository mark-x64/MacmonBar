.PHONY: app build bump-build clean icon macmon notarize release run sign test zip

SWIFT_ENV = CLANG_MODULE_CACHE_PATH="$(CURDIR)/.build/clang-module-cache"

macmon:
	cd ../macmon && cargo build --release

icon:
	./Scripts/generate-app-icon.sh

build:
	$(SWIFT_ENV) swift build

bump-build:
	./Scripts/bump-build-number.sh

release:
	$(SWIFT_ENV) swift build -c release

test:
	$(SWIFT_ENV) swift test

run: macmon
	$(SWIFT_ENV) MACMON_BIN="$(CURDIR)/../macmon/target/release/macmon" swift run MacmonBar

app:
	./Scripts/package-app.sh

sign: app
	./Scripts/sign-app.sh

notarize: sign
	./Scripts/notarize-app.sh

zip: app
	./Scripts/create-zip.sh

clean:
	swift package clean
