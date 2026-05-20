#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AskNow"
APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DMG_ROOT="$ROOT_DIR/.build/dmg-root"
DMG_PATH="$ROOT_DIR/.build/$APP_NAME.dmg"
ICONSET_DIR="$ROOT_DIR/.build/$APP_NAME.iconset"
ICNS_PATH="$RESOURCES_DIR/$APP_NAME.icns"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

cd "$ROOT_DIR"

echo "Building $APP_NAME.app..."
"$ROOT_DIR/Scripts/build_app.sh"

echo "Generating app icon..."
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR" "$RESOURCES_DIR"

swift - "$ICONSET_DIR" <<'SWIFT'
import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)

let icons: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func drawSparkle(center: CGPoint, radius: CGFloat, color: NSColor) {
    let path = NSBezierPath()
    let long = radius
    let short = radius * 0.28
    let points = [
        CGPoint(x: center.x, y: center.y + long),
        CGPoint(x: center.x + short, y: center.y + short),
        CGPoint(x: center.x + long, y: center.y),
        CGPoint(x: center.x + short, y: center.y - short),
        CGPoint(x: center.x, y: center.y - long),
        CGPoint(x: center.x - short, y: center.y - short),
        CGPoint(x: center.x - long, y: center.y),
        CGPoint(x: center.x - short, y: center.y + short),
    ]

    path.move(to: points[0])
    for point in points.dropFirst() {
        path.line(to: point)
    }
    path.close()
    color.setFill()
    path.fill()
}

for icon in icons {
    let side = CGFloat(icon.pixels)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: icon.pixels,
        pixelsHigh: icon.pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Unable to create bitmap for \(icon.name)")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high

    let bounds = NSRect(x: 0, y: 0, width: side, height: side)
    let cornerRadius = side * 0.22
    let background = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor.white.setFill()
    background.fill()

    drawSparkle(
        center: CGPoint(x: side * 0.50, y: side * 0.55),
        radius: side * 0.27,
        color: NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.09, alpha: 1)
    )
    drawSparkle(
        center: CGPoint(x: side * 0.70, y: side * 0.72),
        radius: side * 0.095,
        color: NSColor(calibratedRed: 0.24, green: 0.26, blue: 0.30, alpha: 1)
    )
    drawSparkle(
        center: CGPoint(x: side * 0.31, y: side * 0.30),
        radius: side * 0.075,
        color: NSColor(calibratedRed: 0.24, green: 0.26, blue: 0.30, alpha: 1)
    )

    bitmap.size = NSSize(width: side, height: side)
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode \(icon.name)")
    }
    try pngData.write(to: outputURL.appendingPathComponent(icon.name))
}
SWIFT

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"
"$PLIST_BUDDY" -c "Set :CFBundleIconFile $APP_NAME" "$CONTENTS_DIR/Info.plist" 2>/dev/null \
    || "$PLIST_BUDDY" -c "Add :CFBundleIconFile string $APP_NAME" "$CONTENTS_DIR/Info.plist"

echo "Ad-hoc signing $APP_NAME.app..."
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "Creating DMG staging folder..."
rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

echo "Creating $DMG_PATH..."
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

hdiutil verify "$DMG_PATH"

echo "Built $DMG_PATH"
echo "This DMG is not Developer ID signed or notarized. Users may need to allow it in macOS security settings."
