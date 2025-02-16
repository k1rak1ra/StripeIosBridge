#!/bin/bash

# Variables
SCHEME="StripeIosBridge"
CONFIGURATION="Debug"
OUTPUT_DIR="./output"

# Clean output directory
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Build for iOS Simulator
echo "Building for iOS Simulator..."
xcodebuild archive \
  -scheme $SCHEME \
  -configuration $CONFIGURATION \
  -destination 'generic/platform=iOS Simulator' \
  -archivePath $OUTPUT_DIR/$SCHEME-iOS-Simulator.xcarchive \
  -sdk iphonesimulator \
  SKIP_INSTALL=NO

# Verify iOS Simulator framework
if [ -d "$OUTPUT_DIR/$SCHEME-iOS-Simulator.xcarchive/Products/Library/Frameworks/$SCHEME.framework" ]; then
  echo "iOS Simulator framework found."
else
  echo "Error: iOS Simulator framework not found!"
  exit 1
fi

# Build for iOS Device
echo "Building for iOS Device..."
xcodebuild archive \
  -scheme $SCHEME \
  -configuration $CONFIGURATION \
  -destination 'generic/platform=iOS' \
  -archivePath $OUTPUT_DIR/$SCHEME-iOS.xcarchive \
  -sdk iphoneos \
  SKIP_INSTALL=NO

# Verify iOS Device framework
if [ -d "$OUTPUT_DIR/$SCHEME-iOS.xcarchive/Products/Library/Frameworks/$SCHEME.framework" ]; then
  echo "iOS Device framework found."
else
  echo "Error: iOS Device framework not found!"
  exit 1
fi

# Create XCFramework directory structure
mkdir -p ./output/StripeIosBridge.xcframework

# Copy iOS Simulator framework
mkdir -p ./output/StripeIosBridge.xcframework/ios-arm64_x86_64-simulator
cp -r ./output/StripeIosBridge-iOS-Simulator.xcarchive/Products/Library/Frameworks/StripeIosBridge.framework ./output/StripeIosBridge.xcframework/ios-arm64_x86_64-simulator/

# Copy iOS Device framework
mkdir -p ./output/StripeIosBridge.xcframework/ios-arm64
cp -r ./output/StripeIosBridge-iOS.xcarchive/Products/Library/Frameworks/StripeIosBridge.framework ./output/StripeIosBridge.xcframework/ios-arm64/

# Create Info.plist
cat <<EOF > ./output/StripeIosBridge.xcframework/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>AvailableLibraries</key>
  <array>
    <dict>
      <key>LibraryIdentifier</key>
      <string>ios-arm64</string>
      <key>LibraryPath</key>
      <string>StripeIosBridge.framework</string>
      <key>SupportedArchitectures</key>
      <array>
        <string>arm64</string>
      </array>
      <key>SupportedPlatform</key>
      <string>ios</string>
    </dict>
    <dict>
      <key>LibraryIdentifier</key>
      <string>ios-arm64_x86_64-simulator</string>
      <key>LibraryPath</key>
      <string>StripeIosBridge.framework</string>
      <key>SupportedArchitectures</key>
      <array>
        <string>arm64</string>
        <string>x86_64</string>
      </array>
      <key>SupportedPlatform</key>
      <string>ios</string>
      <key>SupportedPlatformVariant</key>
      <string>simulator</string>
    </dict>
  </array>
  <key>CFBundlePackageType</key>
  <string>XFWK</string>
  <key>XCFrameworkFormatVersion</key>
  <string>1.0</string>
</dict>
</plist>
EOF

echo "Manually created XCFramework at: ./output/StripeIosBridge.xcframework"

# Verify XCFramework
if [ -d "$OUTPUT_DIR/$SCHEME.xcframework" ]; then
  echo "XCFramework created successfully at $OUTPUT_DIR/$SCHEME.xcframework"
else
  echo "Error: XCFramework not created!"
  exit 1
fi
