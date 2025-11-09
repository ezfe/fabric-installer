#!/bin/bash

set -e

# Your Developer ID Application certificate name
DEVELOPER_ID="Developer ID Application: Ezekiel Elin (39QG79F7FD)"

# Path to the app bundle
APP_BUNDLE="build/jpackage/Fabric Installer.app"

# --- Sign dylibs and executables ---
echo "Signing dylibs and executables..."
find "$APP_BUNDLE" -type f \( -name "*.dylib" -o -perm +111 \) -exec codesign -vvv --options runtime --deep --force --sign "$DEVELOPER_ID" {} \;
echo "All dylibs and executables signed successfully."
