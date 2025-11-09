#!/bin/bash

set -e

# Your Developer ID Application certificate name
DEVELOPER_APP_ID="Developer ID Application: Ezekiel Elin (39QG79F7FD)"


# Path to the app bundle
APP_BUNDLE="build/jpackage/Fabric Installer.app"


# --- Sign dylib in jar ---
JAR_FILE=$(find "$APP_BUNDLE/Contents/app" -name "*.jar" | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo "Error: Could not find jar file in app bundle."
    exit 1
fi

echo "Signing dylib within $JAR_FILE..."
DYLIB_NAME="natives/macos-x86_64_arm64.dylib"
TMP_DIR=$(mktemp -d)

unzip -q "$JAR_FILE" -d "$TMP_DIR"
codesign -vvv --options runtime --force --sign "$DEVELOPER_APP_ID" "$TMP_DIR/$DYLIB_NAME"
(cd "$TMP_DIR" && zip -q -r "new.jar" .)
mv "$TMP_DIR/new.jar" "$JAR_FILE"

rm -rf "$TMP_DIR"
echo "Dylib signed successfully."


# --- Signing ---
echo "Signing app bundle..."
# Find and sign all dylib and executable files
find "$APP_BUNDLE" -type f \( -name "*.dylib" -o -perm +111 \) -exec codesign -vvv --options runtime --deep --force --sign "$DEVELOPER_APP_ID" {} \;
# Sign the entire app bundle
codesign -vvv --options runtime --force --sign "$DEVELOPER_APP_ID" "$APP_BUNDLE"
echo "App bundle signed successfully."


# --- Zipping ---
echo "Creating zip for notarization..."
ZIP_PATH="build/jpackage/Fabric Installer.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
echo "Zip created at $ZIP_PATH"


# --- Notarization ---
# Ensure APPLE_ID and APP_SPECIFIC_PASSWORD are set as environment variables
if [ -z "$APPLE_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
    echo "Error: APPLE_ID and APP_SPECIFIC_PASSWORD environment variables must be set for notarization."
    echo "You can create an app-specific password at https://appleid.apple.com"
    exit 1
fi

echo "Submitting APP for notarization..."
NOTARIZATION_INFO=$(xcrun notarytool submit "$ZIP_PATH" --apple-id "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD" --team-id 39QG79F7FD --wait --output-format json)
NOTARIZATION_UUID=$(echo "$NOTARIZATION_INFO" | jq -r '.id')
NOTARIZATION_STATUS=$(echo "$NOTARIZATION_INFO" | jq -r '.status')

if [ "$NOTARIZATION_STATUS" != "Accepted" ]; then
    echo "Error: Notarization failed."
    echo "Notarization status: $NOTARIZATION_STATUS"
    xcrun notarytool log "$NOTARIZATION_UUID" --apple-id "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD" --team-id 39QG79F7FD
    exit 1
fi

echo "Notarization successful."

# --- Cleanup ---
echo "Removing temporary zip file..."
rm "$ZIP_PATH"


# --- Stapling ---
echo "Stapling notarization ticket to APP..."
xcrun stapler staple "$APP_BUNDLE"
echo "Stapling complete."

echo "Process complete. Final APP is at $APP_BUNDLE"
