#!/usr/bin/env swift
import AppKit

/// macOS App Icon: rounded square, night gradient, crescent + stars.
/// Renders each PNG at **exact** pixel dimensions (Retina-safe). `NSImage.lockFocus()` on a
/// 2x display produces wrong pixel sizes and breaks Finder / Launchpad icons.
let sizes = [16, 32, 64, 128, 256, 512, 1024]

guard CommandLine.arguments.count >= 2 else {
	fputs("usage: swift generate_app_icons.swift <output_dir>\n", stderr)
	exit(1)
}
let outDir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)

func starPath(cx: CGFloat, cy: CGFloat, r: CGFloat) -> NSBezierPath {
	let p = NSBezierPath()
	for i in 0..<10 {
		let angle = CGFloat(i) * .pi / 5 - .pi / 2
		let rad = (i % 2 == 0) ? r : r * 0.4
		let x = cx + cos(angle) * rad
		let y = cy + sin(angle) * rad
		if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
		else { p.line(to: CGPoint(x: x, y: y)) }
	}
	p.close()
	return p
}

/// Draw into the current AppKit graphics context (bitmap rep). `s` is side length in points (= pixels here).
func drawIconContent(s: CGFloat) {
	let corner = s * 0.2237
	let mask = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: s, height: s), xRadius: corner, yRadius: corner)
	mask.addClip()

	let g = NSGradient(colors: [
		NSColor(red: 0.04, green: 0.11, blue: 0.30, alpha: 1),
		NSColor(red: 0.10, green: 0.20, blue: 0.45, alpha: 1),
		NSColor(red: 0.14, green: 0.26, blue: 0.52, alpha: 1)
	], atLocations: [0, 0.5, 1], colorSpace: .deviceRGB)
	g?.draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: 100)

	NSColor.white.withAlphaComponent(0.06).setFill()
	let glow = NSBezierPath(ovalIn: NSRect(x: s * 0.05, y: s * 0.55, width: s * 0.55, height: s * 0.45))
	glow.fill()

	let mx = s * 0.48
	let my = s * 0.52
	let bigR = s * 0.32
	let moon = NSBezierPath(ovalIn: NSRect(x: mx - bigR, y: my - bigR, width: bigR * 2, height: bigR * 2))
	let biteR = s * 0.26
	let bx = mx + s * 0.085
	let by = my - s * 0.03
	let bite = NSBezierPath(ovalIn: NSRect(x: bx - biteR, y: by - biteR, width: biteR * 2, height: biteR * 2))
	moon.append(bite)
	moon.windingRule = .evenOdd
	NSColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1).setFill()
	moon.fill()

	NSColor(red: 1.0, green: 0.86, blue: 0.38, alpha: 1).setFill()
	starPath(cx: s * 0.74, cy: s * 0.36, r: s * 0.05).fill()
	starPath(cx: s * 0.82, cy: s * 0.5, r: s * 0.034).fill()
	NSColor.white.withAlphaComponent(0.95).setFill()
	starPath(cx: s * 0.24, cy: s * 0.38, r: s * 0.026).fill()
	starPath(cx: s * 0.58, cy: s * 0.26, r: s * 0.02).fill()
}

func pngData(exactPixels: Int) -> Data {
	let w = exactPixels
	let h = exactPixels
	guard let rep = NSBitmapImageRep(
		bitmapDataPlanes: nil,
		pixelsWide: w,
		pixelsHigh: h,
		bitsPerSample: 8,
		samplesPerPixel: 4,
		hasAlpha: true,
		isPlanar: false,
		colorSpaceName: .deviceRGB,
		bytesPerRow: 0,
		bitsPerPixel: 0
	) else {
		fatalError("NSBitmapImageRep failed for \(w)x\(h)")
	}
	rep.size = NSSize(width: w, height: h)

	NSGraphicsContext.saveGraphicsState()
	guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
		fatalError("NSGraphicsContext(bitmapImageRep:) failed")
	}
	NSGraphicsContext.current = ctx

	let s = CGFloat(exactPixels)
	drawIconContent(s: s)

	NSGraphicsContext.restoreGraphicsState()

	guard let png = rep.representation(using: .png, properties: [:]) else {
		fatalError("PNG encode failed for \(w)")
	}
	return png
}

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for px in sizes {
	let png = pngData(exactPixels: px)
	try png.write(to: outDir.appendingPathComponent("icon_\(px).png"))
}
print("OK: \(sizes.count) icons → \(outDir.path)")
