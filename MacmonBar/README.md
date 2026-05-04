# Macmon Bar

Macmon Bar is a native SwiftUI menu bar wrapper around the bundled
[`MacmonBarRuntime`](../MacmonBarRuntime) Rust sampler.

For user-facing project documentation, release rules, signing, and GitHub
publishing notes, see the root [README](../README.md) and
[RELEASING](../RELEASING.md) documents.

The repository is split deliberately:

- `../MacmonBarRuntime` is the first-party Rust agent bundled in releases.
- `../macmon` is the upstream Rust project reference. Keep it clean so it can be updated with `git pull`.
- `MacmonBar` is the macOS app. It starts a continuous `macmon pipe --soc-info` JSON stream, updates the menu bar title on every sample, and renders live value-over-time charts in the popover.

## Requirements

- macOS 14 or newer
- Xcode 26 / Swift 6.2
- Rust toolchain for building the bundled runtime

## Development

```sh
make macmon
make test
make run
```

`make run` sets `MACMON_BIN` to `../MacmonBarRuntime/target/release/macmon`,
so the app always uses the local source build.

## Build an app bundle

```sh
make app
open dist/MacmonBar.app
```

The packaging script builds both Swift and Rust release binaries, then bundles
the runtime executable into:

```text
dist/MacmonBar.app/Contents/Resources/bin/macmon
```

The app also supports `MACMON_BIN` and Homebrew locations as fallbacks, which keeps development and future packaging paths separate.

## Updating Runtime From Upstream

```sh
cd ../macmon
git pull
cd ../MacmonBarRuntime
# port or cherry-pick the upstream changes intentionally
cd ../MacmonBar
make test
make app
```

Keep Macmon Bar-specific runtime changes in `../MacmonBarRuntime`, not in the
upstream reference submodule. If upstream changes the JSON format, update
`Sources/MacmonBar/Models/MetricSnapshot.swift` first and keep a decoding test
in `Tests/MacmonBarTests`.
