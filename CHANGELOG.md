# Changelog

## 1.0.0 - 2026-06-23

- Created the Flutter desktop app for Linux, macOS, and Windows.
- Added image loading, preview, resize presets, custom resize, format selection, and Apply export flow.
- Added configurable app defaults through `AppSettings`.
- Added WEBP export through bundled `cwebp` binaries.
- Added PNG and JPEG export support.
- Added sanitized underscore filenames with configurable max base filename length.
- Added Linux `.desktop` image MIME registration metadata.
- Added macOS image document type registration metadata.
- Added macOS file access entitlements for file picker dialogs and Downloads exports.
- Added launcher icon generation for macOS and Windows through `flutter_launcher_icons`.
- Added Linux hicolor launcher icon assets from the same source icon.
- Added launch/open-file handling for Linux command-line paths and macOS Finder open events.
- Added README, changelog, roadmap, and baseline tests.
