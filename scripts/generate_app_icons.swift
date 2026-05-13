#!/usr/bin/env swift
import AppKit

/// macOS App Icon: rounded square, night gradient, crescent + stars.
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

func drawIcon(pixels: Int) -> NSImage {
	let s = CGFloat(pixels)
	let img = NSImage(size: NSSize(width: s, height: s))
	img.lockFocus()

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

	// Crescent: full disk minus smaller offset disk (even-odd)
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

	img.unlockFocus()
	return img
}

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for px in sizes {
	let img = drawIcon(pixels: px)
	guard let tiff = img.tiffRepresentation,
	      let rep = NSBitmapImageRep(data: tiff),
	      let png = rep.representation(using: .png, properties: [:]) else { fatalError("png \(px)") }
	try png.write(to: outDir.appendingPathComponent("icon_\(px).png"))
}
print("OK: \(sizes.count) icons → \(outDir.path)")
