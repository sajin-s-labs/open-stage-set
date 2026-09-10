#!/usr/bin/env bash
set -e

VERSION="${1:-1.0.0}"
BUNDLE_DIR="build/linux/x64/release/bundle"
DIST_DIR="dist"

mkdir -p "$DIST_DIR"

echo "=== Packaging Linux Releases for Open Stage Set v${VERSION} ==="

# 1. Standalone Tarball (.tar.gz)
echo "--> Creating tar.gz portable archive..."
tar -czvf "${DIST_DIR}/open-stage-set-linux-x64.tar.gz" -C "$BUNDLE_DIR" .

# 2. AppImage (.AppImage)
echo "--> Building AppImage..."
APPDIR="build/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib/open-stage-set"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

cp -r "$BUNDLE_DIR"/* "$APPDIR/usr/lib/open-stage-set/"
ln -sf "../lib/open-stage-set/open_stage_set" "$APPDIR/usr/bin/open_stage_set"
cp packaging/linux/open-stage-set.desktop "$APPDIR/open-stage-set.desktop"
cp packaging/linux/open-stage-set.desktop "$APPDIR/usr/share/applications/open-stage-set.desktop"
cp assets/images/logo.png "$APPDIR/open-stage-set.png"
cp assets/images/logo.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/open-stage-set.png"
cp packaging/linux/AppRun "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"

if [ ! -f "appimagetool" ]; then
  curl -sSL -o appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool
fi

ARCH=x86_64 ./appimagetool --appimage-extract-and-run "$APPDIR" "${DIST_DIR}/open-stage-set-x86_64.AppImage"

# 3. System Packaging Root for FPM (deb, rpm, arch)
echo "--> Preparing FPM staging root..."
STAGING_DIR="build/fpm-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/usr/bin"
mkdir -p "$STAGING_DIR/usr/lib/open-stage-set"
mkdir -p "$STAGING_DIR/usr/share/applications"
mkdir -p "$STAGING_DIR/usr/share/icons/hicolor/256x256/apps"

cp -r "$BUNDLE_DIR"/* "$STAGING_DIR/usr/lib/open-stage-set/"
ln -sf "/usr/lib/open-stage-set/open_stage_set" "$STAGING_DIR/usr/bin/open_stage_set"
cp packaging/linux/open-stage-set.desktop "$STAGING_DIR/usr/share/applications/"
cp assets/images/logo.png "$STAGING_DIR/usr/share/icons/hicolor/256x256/apps/open-stage-set.png"

# Common FPM parameters
FPM_COMMON_ARGS=(
  -s dir
  -C "$STAGING_DIR"
  -n "open-stage-set"
  -v "$VERSION"
  --license "MIT"
  --vendor "Sajin's Labs"
  --maintainer "Sajin <sajin@example.com>"
  --url "https://github.com/sajin-s-labs/open-stage-set"
  --description "Open Stage Set: distraction-free monochrome live performance & setlist companion for musicians"
  --category "AudioVideo"
)

# 4. Debian / Ubuntu (.deb)
echo "--> Building .deb package..."
fpm "${FPM_COMMON_ARGS[@]}" \
  -t deb \
  -p "${DIST_DIR}/open-stage-set-linux-amd64.deb" \
  -d "libgtk-3-0" \
  -d "libblkid1" \
  -d "liblzma5"

# 5. Fedora / RHEL / openSUSE (.rpm)
echo "--> Building .rpm package..."
fpm "${FPM_COMMON_ARGS[@]}" \
  -t rpm \
  -p "${DIST_DIR}/open-stage-set-linux-x86_64.rpm" \
  -d "gtk3"

# 6. Arch Linux (.pkg.tar.zst)
echo "--> Building Arch Linux package (.pkg.tar.zst)..."
fpm "${FPM_COMMON_ARGS[@]}" \
  -t pacman \
  -p "${DIST_DIR}/open-stage-set-linux-x86_64.pkg.tar.zst" \
  -d "gtk3"

echo "=== Linux Packaging Complete! Generated files in ${DIST_DIR}/ ==="
ls -lh "$DIST_DIR"
