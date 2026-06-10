#!/bin/bash

APP_NAME="Comnyang"
APP_BUNDLE="$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

echo "Building $APP_NAME..."

# Create bundle directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy Info.plist
cp Info.plist "$APP_BUNDLE/Contents/"

# Compile Swift files
swiftc -o "$MACOS_DIR/$APP_NAME" Sources/*.swift -target arm64-apple-macos13.0

if [ $? -eq 0 ]; then
    echo "Build successful! App bundle created at $APP_BUNDLE"
else
    echo "Build failed!"
    exit 1
fi
