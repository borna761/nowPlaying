#!/bin/bash

# Build script for Now Playing macOS app (without Xcode)

set -e

APP_NAME="NowPlaying"
APP_BUNDLE="${APP_NAME}.app"
EXECUTABLE_PATH="${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
RESOURCES_PATH="${APP_BUNDLE}/Contents/Resources"
INFO_PLIST="${APP_BUNDLE}/Contents/Info.plist"

echo "Building ${APP_NAME}..."

# Clean previous build
rm -rf "${APP_BUNDLE}"

# Create app bundle structure
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TARGET="arm64-apple-macosx11.0"
else
    TARGET="x86_64-apple-macosx11.0"
fi

# Compile Swift files into executable
echo "Compiling Swift files for ${ARCH}..."
swiftc -o "${EXECUTABLE_PATH}" \
    -target "${TARGET}" \
    -module-name "${APP_NAME}" \
    -sdk $(xcrun --show-sdk-path) \
    main.swift \
    NowPlayingApp.swift \
    MediaControl.swift \
    MenuController.swift

# Check if compilation succeeded
if [ ! -f "${EXECUTABLE_PATH}" ]; then
    echo "Error: Compilation failed"
    exit 1
fi

# Make executable
chmod +x "${EXECUTABLE_PATH}"

# Copy Info.plist
if [ -f "Info.plist" ]; then
    cp "Info.plist" "${INFO_PLIST}"
else
    echo "Warning: Info.plist not found"
fi

# Copy app icon (referenced by Info.plist's CFBundleIconFile)
if [ -f "${APP_NAME}.icns" ]; then
    cp "${APP_NAME}.icns" "${RESOURCES_PATH}/${APP_NAME}.icns"
else
    echo "Warning: ${APP_NAME}.icns not found"
fi

echo "Build complete! Run with: open ${APP_BUNDLE}"
echo "Or execute directly: ${EXECUTABLE_PATH}"

