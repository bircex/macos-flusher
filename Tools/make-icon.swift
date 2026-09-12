import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
    let inset = rect.insetBy(dx: size * 0.06, dy: size * 0.06)
    let shape = NSBezierPath(roundedRect: inset, xRadius: size * 0.22, yRadius: size * 0.22)
    NSGradient(starting: NSColor(calibratedRed: 0.10, green: 0.55, blue: 0.95, alpha: 1),
               ending: NSColor(calibratedRed: 0.02, green: 0.22, blue: 0.55, alpha: 1))!
        .draw(in: shape, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: size * 0.42, weight: .medium)
    let drive = NSImage(systemSymbolName: "internaldrive.fill", accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!
    let driveRect = NSRect(x: size * 0.16, y: size * 0.30, width: size * 0.56, height: size * 0.40)
    let tinted = NSImage(size: driveRect.size, flipped: false) { r in
        drive.draw(in: r)
        NSColor.white.set()
        r.fill(using: .sourceAtop)
        return true
    }
    tinted.draw(in: driveRect)

    let sparkConfig = NSImage.SymbolConfiguration(pointSize: size * 0.24, weight: .bold)
    let spark = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)!
        .withSymbolConfiguration(sparkConfig)!
    let sparkRect = NSRect(x: size * 0.60, y: size * 0.58, width: size * 0.26, height: size * 0.26)
    let sparkTinted = NSImage(size: sparkRect.size, flipped: false) { r in
        spark.draw(in: r)
        NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.30, alpha: 1).set()
        r.fill(using: .sourceAtop)
        return true
    }
    sparkTinted.draw(in: sparkRect)
    return true
}

let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
