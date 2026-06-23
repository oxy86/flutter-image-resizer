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

## Defaults

Defaults are centralized in `AppSettings` in `lib/main.dart`:

- `defaultFormat`: `WEBP`
- `defaultResizePreset`: `1200x scale`
- `defaultExportDirectory`: system Downloads folder when unset
- `maxBaseFilenameLength`: `32`
- `webpQuality`: `80`
- `jpegQuality`: `90`

This is intentional so a future Settings dialog can update one settings model instead of changing export logic.

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

## Launcher Icons

Launcher icons are generated from `assets/icons/icon-1024.png`.

macOS and Windows assets are generated with:

```sh
dart run flutter_launcher_icons
```

Linux hicolor PNG assets live under `linux/icons/hicolor` and are installed by the Linux CMake bundle step.

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

The app also enables these sandbox entitlements so file dialogs and automatic Downloads exports work:

- `com.apple.security.files.user-selected.read-write`
- `com.apple.security.files.downloads.read-write`

To set it as default for an image type:

1. Build the macOS app.
2. Move or copy the `.app` into `/Applications` or `~/Applications`.
3. Select an image in Finder.
4. Open `Get Info`.
5. Choose Image Resizer under `Open with`.
6. Click `Change All...`.

Finder open events are bridged from `AppDelegate.swift` to Flutter through the `image_resizer/open_file` method channel.
