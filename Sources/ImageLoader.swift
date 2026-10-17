import AppKit
import Foundation
import ImageIO

struct LoadedImage: Sendable {
    let cgImage: CGImage
    let pixelSize: CGSize
    let url: URL
}

enum ImageLoader {
    /// Prefer a display-sized decode first; falls back to full image.
    static func load(url: URL, maxPixelSize: Int = 4096) async -> LoadedImage? {
        await Task.detached(priority: .userInitiated) {
            loadSync(url: url, maxPixelSize: maxPixelSize)
        }.value
    }

    private static func loadSync(url: URL, maxPixelSize: Int) -> LoadedImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else {
            return nil
        }

        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true,
        ]

        let image =
            CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary)
            ?? CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary)

        guard let image else { return nil }

        return LoadedImage(
            cgImage: image,
            pixelSize: CGSize(width: image.width, height: image.height),
            url: url
        )
    }
}
