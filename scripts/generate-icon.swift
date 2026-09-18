import AppKit

// GitHub mark: https://github.com/primer/octicons/blob/main/icons/mark-github-16.svg
// Distributed under the MIT license in Resources/Octicons-LICENSE.

// Run: swift scripts/generate-icon.swift /tmp/GitHubSignal.iconset
// Then: iconutil -c icns /tmp/GitHubSignal.iconset -o Resources/AppIcon.icns
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

func drawIcon(pixels: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)

    let tile = NSBezierPath(roundedRect: NSRect(x: 56, y: 56, width: 912, height: 912), xRadius: 210, yRadius: 210)
    NSGradient(starting: NSColor(calibratedWhite: 1, alpha: 1),
               ending: NSColor(calibratedWhite: 0.88, alpha: 1))!
        .draw(in: tile, angle: -70)

    let mark = NSImage(contentsOfFile: "Resources/GitHubMark.svg")!
    mark.draw(in: NSRect(x: 212, y: 212, width: 600, height: 600))
    NSColor(calibratedRed: 0.16, green: 0.65, blue: 0.46, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 773, y: 773, width: 118, height: 118)).fill()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let suffix = scale == 2 ? "@2x" : ""
        try drawIcon(pixels: size * scale).write(to: directory.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
