import Foundation
import ImageIO
import UniformTypeIdentifiers

enum SupportedFormats {
    static let extensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif",
        "webp", "gif", "tif", "tiff", "bmp",
    ]

    static func isImageExtension(_ url: URL) -> Bool {
        extensions.contains(url.pathExtension.lowercased())
    }

    static func canDecode(_ url: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return false
        }
        return CGImageSourceGetCount(source) > 0
    }

    static var contentTypes: [UTType] {
        [.jpeg, .png, .heic, .heif, .tiff, .bmp, .webP, .gif, .image]
    }
}
