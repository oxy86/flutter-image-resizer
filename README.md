# Flutter Image Resizer

A small Flutter desktop app for loading an image, previewing it, resizing it, and exporting it to another format.

## Features

- Loads and previews image files.
- Default resize preset is `1200x scale`.
- Custom resize mode accepts width, height, or both.
- Default export format is `WEBP`.
- Exports automatically to the configured export directory, currently defaulting to the user's Downloads folder.
- Output filenames are lower-case, underscore-separated, and capped by the configured max base filename length.
- Bundles `cwebp` binaries for WEBP export on Linux, macOS, and Windows desktop builds.
- Registers image file handling metadata for Linux and macOS so the app can appear in `Open With...`.
- Supports `Ctrl+O` / `Cmd+O` to open an image and `Ctrl+S` / `Cmd+S` to export.
- Persists app settings for defaults such as export directory, format, resize, filename length, and export quality.

## Defaults

Defaults are centralized in `AppSettings` in `lib/main.dart`:

- `defaultFormat`: `WEBP`
- `defaultResizePreset`: `1200x scale`
- `defaultExportDirectory`: system Downloads folder when unset
- `maxBaseFilenameLength`: `32`
- `webpQuality`: `80`
- `jpegQuality`: `80`

These defaults can be changed from the Settings dialog.

The default export behavior is equivalent to:

```sh
convert -quality 80 -resize 1200x input.jpg input.webp
```

## Run

```sh
flutter run -d macos
flutter run -d linux
flutter run -d windows
```

## Build

```sh
flutter build macos
flutter build linux
flutter build windows
```

## Tagged Releases

GitHub Actions builds release artifacts for every pushed tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The workflow publishes:

- notarized macOS `.dmg`
- Linux `.AppImage`
- Windows setup `.exe`

For macOS signing and notarization, configure these GitHub repository secrets:

- `MACOS_CERTIFICATE`: base64-encoded Developer ID Application `.p12`
- `MACOS_CERTIFICATE_PASSWORD`: password for that `.p12`
- `AC_APPLE_ID`: Apple ID used for notarization
- `AC_TEAM_ID`: Apple Developer Team ID
- `AC_PASSWORD`: app-specific password for the Apple ID

## Launcher Icons

Launcher icons are generated from `assets/icons/icon-1024.png`.

macOS and Windows assets are generated with:

```sh
dart run flutter_launcher_icons
```

Linux hicolor PNG assets live under `linux/icons/hicolor` and are installed by the Linux CMake bundle step.

If macOS shows the old Flutter icon for one build folder but not another, the bundle usually has the correct `AppIcon.icns` and Finder/Dock is serving a cached icon. Rebuild the target, remove any old Dock entry, and if needed move the `.app` to a new path or clear the icon cache.

## Linux `Open With...`

The project includes `linux/com.example.flutter_image_resizer.desktop` with image MIME types and `%f` file launching.

For development installs, after building on Linux, copy or package the `.desktop` file into an applications directory and refresh the desktop database:

```sh
desktop-file-install --dir="$HOME/.local/share/applications" linux/com.example.flutter_image_resizer.desktop
update-desktop-database "$HOME/.local/share/applications"
```

The `Exec` path in the installed desktop file must point to the built `flutter_image_resizer` executable. After that, Nautilus can show the app in `Open With...`, and users can set it as the default image handler from file properties.

## macOS `Open With...`

The macOS bundle declares image document types in `macos/Runner/Info.plist`. Finder uses this metadata to show the built `.app` in `Open With...`.

The macOS app is intentionally not sandboxed. WEBP export launches the bundled `cwebp` encoder process, and the app sandbox blocks that subprocess with `Operation not permitted`. `file_picker` entitlement checks are skipped at startup on macOS for this non-sandboxed distribution model.

To set it as default for an image type:

1. Build the macOS app.
2. Move or copy the `.app` into `/Applications` or `~/Applications`.
3. Select an image in Finder.
4. Open `Get Info`.
5. Choose Image Resizer under `Open with`.
6. Click `Change All...`.

Finder open events are bridged from `AppDelegate.swift` to Flutter through the `image_resizer/open_file` method channel.
