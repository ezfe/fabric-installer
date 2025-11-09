#!/bin/bash

set -e

# Your Developer ID Application certificate name
DEVELOPER_ID="Developer ID Application: Ezekiel Elin (39QG79F7FD)"

# Path to the app bundle
APP_BUNDLE="build/jpackage/Fabric Installer.app"

# Find and sign all dylib and executable files
find "$APP_BUNDLE" -type f \( -name "*.dylib" -o -perm +111 \) -exec codesign -vvv --options runtime --deep --force --sign "$DEVELOPER_ID" {} \;

echo "All internal files signed successfully."

# Sign the entire app bundle
echo "Signing the app bundle..."
codesign -vvv --force --sign "$DEVELOPER_ID" "$APP_BUNDLE"
echo "App bundle signed successfully."

echo "All files signed successfully."
