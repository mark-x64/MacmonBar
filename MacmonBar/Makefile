.PHONY: app build bump-build clean icon macmon notarize release run sign test zip

SWIFT_ENV = CLANG_MODULE_CACHE_PATH="$(CURDIR)/.build/clang-module-cache"
RUNTIME_DIR = $(CURDIR)/../MacmonBarRuntime

macmon:
	cargo build --manifest-path "$(RUNTIME_DIR)/Cargo.toml" --release

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
	$(SWIFT_ENV) MACMON_BIN="$(RUNTIME_DIR)/target/release/macmon" swift run MacmonBar

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
