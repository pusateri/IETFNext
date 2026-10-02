//
//  FloorMapImage.swift
//  IETFNext
//
//  Loads a venue floor map, trims its blank margins, and shows it zoomable.
//

import SwiftUI
import CoreGraphics
import ImageIO

/// A floor-map image for a room.
///
/// Floor maps are published with wide white margins (sometimes a third of the image).
/// This loads the image, crops it to the drawing plus a little padding, and shows it in a
/// `ZoomableContainer`. The map is color-inverted in dark mode, as before.
struct FloorMapImage: View {
    let url: URL

    @Environment(\.colorScheme) private var colorScheme
    @State private var image: CGImage?
    @State private var failed = false

    var body: some View {
        content
            .task(id: url) {
                image = nil
                failed = false
                if let trimmed = await loadTrimmedFloorMap(from: url) {
                    withAnimation(.spring) { image = trimmed }
                } else {
                    failed = true
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            // Pinch, drag, or double-tap to zoom into the floor map.
            ZoomableContainer {
                let map = Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                if colorScheme == .dark {
                    map.colorInvert()
                } else {
                    map
                }
            }
            .transition(.scale)
        } else if !failed {
            ProgressView()
        }
    }
}

/// Downloads and decodes the map, then trims its margins, off the main actor.
@concurrent
private func loadTrimmedFloorMap(from url: URL) async -> CGImage? {
    guard let (data, _) = try? await URLSession.shared.data(from: url),
          let source = CGImageSourceCreateWithData(data as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        return nil
    }
    return trimmingBlankMargins(of: image)
}

/// Crops `image` to the bounding box of its non-white content, plus `paddingFraction` of the
/// larger dimension on each side. Transparent pixels count as white. Returns the original image
/// if it has no content or can't be measured.
private func trimmingBlankMargins(of image: CGImage, whiteThreshold: UInt8 = 240,
                                  paddingFraction: CGFloat = 0.01) -> CGImage {
    let width = image.width, height = image.height
    guard width > 0, height > 0,
          let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                  bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return image
    }
    // Composite onto white so transparent areas are treated as blank.
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else { return image }
    let bytesPerRow = context.bytesPerRow

    // Bitmap rows run top to bottom, matching CGImage cropping coordinates.
    // Sampling every other pixel is plenty to find the drawing's edges.
    var minX = width, minY = height, maxX = -1, maxY = -1
    for y in stride(from: 0, to: height, by: 2) {
        let row = pixels + y * bytesPerRow
        for x in stride(from: 0, to: width, by: 2) {
            let pixel = row + x * 4
            if pixel[0] < whiteThreshold || pixel[1] < whiteThreshold || pixel[2] < whiteThreshold {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
    }
    guard maxX >= minX, maxY >= minY else { return image }

    let padding = Int(CGFloat(max(width, height)) * paddingFraction) + 2
    let left = max(0, minX - padding), top = max(0, minY - padding)
    let right = min(width, maxX + padding + 1), bottom = min(height, maxY + padding + 1)
    let crop = CGRect(x: left, y: top, width: right - left, height: bottom - top)
    return image.cropping(to: crop) ?? image
}
