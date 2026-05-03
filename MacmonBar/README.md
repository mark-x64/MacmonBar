# MacmonBar

MacmonBar is a native SwiftUI menu bar wrapper around the upstream [`macmon`](../macmon) sampler.

The repository is split deliberately:

- `../macmon` is the upstream Rust project. Keep it clean so it can be updated with `git pull`.
- `MacmonBar` is the macOS app. It starts a continuous `macmon pipe --soc-info` JSON stream, updates the menu bar title on every sample, and renders live value-over-time charts in the popover.

## Requirements

- macOS 14 or newer
- Xcode 26 / Swift 6.2
- Rust toolchain for building the upstream `macmon` binary

## Development

```sh
make macmon
make test
make run
```

`make run` sets `MACMON_BIN` to the sibling upstream checkout, so the app always uses the local source build.

## Build an app bundle

```sh
make app
open dist/MacmonBar.app
```

The packaging script builds both Swift and Rust release binaries, then bundles the `macmon` executable into:

```text
dist/MacmonBar.app/Contents/Resources/bin/macmon
```

The app also supports `MACMON_BIN` and Homebrew locations as fallbacks, which keeps development and future packaging paths separate.

## Updating upstream macmon

```sh
cd ../macmon
git pull
cd ../MacmonBar
make test
make app
```

If upstream changes the JSON format, update `Sources/MacmonBar/Models/MetricSnapshot.swift` first and keep a decoding test in `Tests/MacmonBarTests`.
