#!/usr/bin/env bash
set -e

# Navigate to mobile project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=========================================="
echo " Building RakshaNet iOS Release Bundle"
echo "=========================================="

flutter pub get

# Build iOS release without code signing (can be signed via Sideloadly, AltStore, or Xcode)
flutter build ios --release --no-codesign

echo "=========================================="
echo " Packaging Runner.app into RakshaNet.ipa"
echo "=========================================="

OUTPUT_DIR="build/ios/ipa"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/Payload"

# Copy Runner.app into Payload directory
cp -r build/ios/iphoneos/Runner.app "$OUTPUT_DIR/Payload/"

# Create IPA archive
cd "$OUTPUT_DIR"
zip -qr "RakshaNet.ipa" "Payload"
rm -rf "Payload"

echo "=========================================="
echo " [SUCCESS] IPA Generated Successfully!"
echo " Output: mobile/$OUTPUT_DIR/RakshaNet.ipa"
echo "=========================================="
