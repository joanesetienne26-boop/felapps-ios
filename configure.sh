#!/bin/bash
# Generates the Xcode project definition and app assets from environment
# variables supplied by Felapps through the Codemagic build API.
set -euo pipefail

: "${APP_NAME:?APP_NAME is required}"
: "${BUNDLE_ID:?BUNDLE_ID is required}"
: "${WEB_URL:?WEB_URL is required}"
APP_VERSION="${APP_VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
TEAM_ID="${TEAM_ID:-}"
DEEP_LINK_SCHEME="${DEEP_LINK_SCHEME:-}"
ORIENTATIONS="${ORIENTATIONS:-all}"
ENABLE_SWIPE_NAVIGATION="${ENABLE_SWIPE_NAVIGATION:-true}"
SPLASH_BG_COLOR="${SPLASH_BG_COLOR:-#ffffff}"

mkdir -p Sources "Resources/Assets.xcassets/AppIcon.appiconset" "Resources/Assets.xcassets/LaunchBackground.colorset"

# App icon: uploaded icon from Felapps when provided, fallback icon otherwise.
if [ -n "${ICON_PNG_BASE64:-}" ]; then
  printf '%s' "$ICON_PNG_BASE64" | base64 --decode > "Resources/Assets.xcassets/AppIcon.appiconset/icon.png"
else
  cp DefaultIcon.png "Resources/Assets.xcassets/AppIcon.appiconset/icon.png"
fi

cat > "Resources/Assets.xcassets/AppIcon.appiconset/Contents.json" <<'EOF'
{
  "images" : [
    {
      "filename" : "icon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF

HEX="${SPLASH_BG_COLOR#\#}"
R=$((16#${HEX:0:2}))
G=$((16#${HEX:2:2}))
B=$((16#${HEX:4:2}))

cat > "Resources/Assets.xcassets/LaunchBackground.colorset/Contents.json" <<EOF
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "$B", "green" : "$G", "red" : "$R" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF

cat > "Resources/Assets.xcassets/Contents.json" <<'EOF'
{ "info" : { "author" : "xcode", "version" : 1 } }
EOF

cat > Sources/AppConfig.swift <<EOF
enum AppConfig {
    static let webUrl = "$WEB_URL"
    static let enableSwipeNavigation = $ENABLE_SWIPE_NAVIGATION
}
EOF

if [ "$ORIENTATIONS" = "portrait" ]; then
  ORIENT_LIST="          - UIInterfaceOrientationPortrait"
else
  ORIENT_LIST="          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight"
fi

URL_TYPES=""
if [ -n "$DEEP_LINK_SCHEME" ]; then
  URL_TYPES="        CFBundleURLTypes:
          - CFBundleURLSchemes:
              - $DEEP_LINK_SCHEME
"
fi

cat > project.yml <<EOF
name: Felapp
options:
  deploymentTarget:
    iOS: "15.0"
settings:
  base:
    SWIFT_VERSION: "5.9"
    DEVELOPMENT_TEAM: "$TEAM_ID"
    MARKETING_VERSION: "$APP_VERSION"
    CURRENT_PROJECT_VERSION: "$BUILD_NUMBER"
    CODE_SIGN_STYLE: Automatic
targets:
  FelappApp:
    type: application
    platform: iOS
    sources:
      - path: Sources
      - path: Resources
        buildPhase: resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: "$BUNDLE_ID"
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        TARGETED_DEVICE_FAMILY: "1,2"
    info:
      path: Sources/Info.plist
      properties:
        CFBundleDisplayName: "$APP_NAME"
        UILaunchScreen:
          UIColorName: LaunchBackground
        NSAppTransportSecurity:
          NSAllowsArbitraryLoads: true
        ITSAppUsesNonExemptEncryption: false
        UISupportedInterfaceOrientations:
$ORIENT_LIST
        UIRequiresFullScreen: true
$URL_TYPES
EOF

echo "project.yml generated for $APP_NAME ($BUNDLE_ID)"
