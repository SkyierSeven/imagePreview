import Foundation

struct DirectoryNavigator: Sendable {
    let urls: [URL]
    let index: Int

    var currentURL: URL? {
        guard urls.indices.contains(index) else { return nil }
        return urls[index]
    }

    var count: Int { urls.count }

    var positionLabel: String {
        guard !urls.isEmpty else { return "0 / 0" }
        return "\(index + 1) / \(urls.count)"
    }

    var canGoPrevious: Bool { index > 0 }
    var canGoNext: Bool { index + 1 < urls.count }

    static func build(around url: URL) -> DirectoryNavigator {
        let fileURL = url.standardizedFileURL
        let directory = fileURL.deletingLastPathComponent()

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return DirectoryNavigator(urls: [fileURL], index: 0)
        }

        let images = contents
            .filter { SupportedFormats.isImageExtension($0) }
            .sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }

        if let idx = images.firstIndex(where: { $0.standardizedFileURL == fileURL }) {
            return DirectoryNavigator(urls: images, index: idx)
        }

        // Opened file has no extension (or odd name) but can still be shown.
        var withCurrent = images
        let insertIndex = withCurrent.firstIndex {
            $0.lastPathComponent.localizedStandardCompare(fileURL.lastPathComponent) != .orderedAscending
        } ?? withCurrent.endIndex
        withCurrent.insert(fileURL, at: insertIndex)
        return DirectoryNavigator(urls: withCurrent, index: insertIndex)
    }

    func previous() -> DirectoryNavigator? {
        guard canGoPrevious else { return nil }
        return DirectoryNavigator(urls: urls, index: index - 1)
    }

    func next() -> DirectoryNavigator? {
        guard canGoNext else { return nil }
        return DirectoryNavigator(urls: urls, index: index + 1)
    }
}
