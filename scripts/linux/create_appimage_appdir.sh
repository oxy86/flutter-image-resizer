#!/usr/bin/env bash
set -euo pipefail

binary_name="flutter_image_resizer"
app_id="com.example.flutter_image_resizer"
bundle_dir="build/linux/x64/release/bundle"
appdir="build/linux/AppDir"

if [[ ! -x "$bundle_dir/$binary_name" ]]; then
  echo "Missing Linux release bundle at $bundle_dir" >&2
  exit 1
fi

rm -rf "$appdir"
mkdir -p \
  "$appdir/usr/lib/$binary_name" \
  "$appdir/usr/share/applications" \
  "$appdir/usr/share/icons"

cp -a "$bundle_dir/." "$appdir/usr/lib/$binary_name/"
cp "linux/$app_id.desktop" "$appdir/$app_id.desktop"
cp "linux/$app_id.desktop" "$appdir/usr/share/applications/$app_id.desktop"
cp -a linux/icons/hicolor "$appdir/usr/share/icons/"
cp linux/icons/hicolor/256x256/apps/flutter_image_resizer.png "$appdir/flutter_image_resizer.png"

cat > "$appdir/AppRun" <<'APPRUN'
#!/usr/bin/env bash
set -euo pipefail

here="$(dirname "$(readlink -f "$0")")"
export XDG_DATA_DIRS="$here/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
exec "$here/usr/lib/flutter_image_resizer/flutter_image_resizer" "$@"
APPRUN

chmod +x "$appdir/AppRun"
