# Changelog

## 1.0.0 - 2026-06-23

- Created the Flutter desktop app for Linux, macOS, and Windows.
- Added image loading, preview, resize presets, custom resize, format selection, and Apply export flow.
- Added configurable app defaults through `AppSettings`.
- Added WEBP export through bundled `cwebp` binaries.
- Added PNG and JPEG export support.
- Added `Ctrl+O` / `Cmd+O` for opening images and `Ctrl+S` / `Cmd+S` for exporting.
- Added sanitized underscore filenames with configurable max base filename length.
- Added Linux `.desktop` image MIME registration metadata.
- Added macOS image document type registration metadata.
- Configured macOS as a non-sandboxed app so bundled WEBP export can execute `cwebp`.
- Added launcher icon generation for macOS and Windows through `flutter_launcher_icons`.
- Added Linux hicolor launcher icon assets from the same source icon.
- Added a tag-triggered GitHub Actions release workflow.
- Added macOS zipped `.app` release artifact generation.
- Added Linux AppImage release artifact generation.
- Added Windows setup release artifact generation with Inno Setup.
- Added launch/open-file handling for Linux command-line paths and macOS Finder open events.
- Added MIT license.
- Added README, changelog, roadmap, and baseline tests.
- Updated `.gitignore` for Flutter desktop artifacts while preserving the bundled Windows `cwebp.exe`.
