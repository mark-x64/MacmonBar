# Releasing MacmonBar

This project ships outside the Mac App Store, so public releases should use a
Developer ID Application certificate, Apple's notarization service, and a zip
artifact attached to a GitHub Release.

## One-Time Apple Setup

1. Join the Apple Developer Program.
2. Create and install a `Developer ID Application` certificate in Keychain.
3. Create a notary keychain profile:

```sh
xcrun notarytool store-credentials macmonbar-notary
```

Use an Apple ID, Team ID, and app-specific password or App Store Connect API key
when prompted. Do not commit credentials to the repository.

Check whether the signing identity is installed:

```sh
security find-identity -v -p codesigning
```

The identity should look like:

```text
Developer ID Application: Your Name (TEAMID)
```

## Version Bump Rules

MacmonBar uses semantic versions: `MAJOR.MINOR.PATCH`.

- Patch: small fixes, visual polish, performance tweaks, dependency updates, or
  release-process fixes. Example: `0.1.0` -> `0.1.1`.
- Minor: larger UI changes, new settings, new visible metrics, or meaningful
  feature additions. Reset patch to 0. Example: `0.1.3` -> `0.2.0`.
- Major: only after explicit maintainer confirmation. Use for breaking changes,
  major architecture shifts, a major minimum macOS version change, or a product
  direction reset.

`CFBundleVersion` is the build number. Increase it by 1 for every public
release.

The source of truth is:

```text
MacmonBar/Support/Info.plist
```

## Build

```sh
cd MacmonBar
make test
make app
```

The app bundle is created at:

```text
MacmonBar/dist/MacmonBar.app
```

## Sign

Set the exact identity from Keychain:

```sh
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
make sign
```

The script signs nested code first:

1. `MacmonBar.app/Contents/Resources/bin/macmon`
2. `MacmonBar.app`

It uses hardened runtime and timestamps.

## Notarize and Staple

```sh
export NOTARY_PROFILE="macmonbar-notary"
make notarize
```

The notarization script creates a temporary zip for upload, waits for Apple's
notary service, staples the ticket to the app, validates the ticket, and then
creates the final release zip.

## Create a Zip Without Signing

For local smoke testing only:

```sh
make zip
```

Unsigned zips are not suitable for public GitHub releases.

## GitHub Release

1. Tag the release:

```sh
git tag v0.1.0
git push origin v0.1.0
```

2. Create a GitHub Release from the tag.
3. Upload:

```text
MacmonBar/dist/MacmonBar-<version>.zip
MacmonBar/dist/MacmonBar-<version>.zip.sha256
```

4. Keep release notes short and user-facing.

## Verify a Release Artifact

After unzipping:

```sh
codesign --verify --deep --strict --verbose=2 MacmonBar.app
xcrun stapler validate MacmonBar.app
spctl -a -vvv -t install MacmonBar.app
```
