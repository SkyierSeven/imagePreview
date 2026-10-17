import Foundation
import Observation

/// Manga-oriented reading options (persisted).
@MainActor
@Observable
final class ReadingPreferences {
    static let shared = ReadingPreferences()

    private enum Keys {
        static let rightToLeft = "reading.rightToLeft"
    }

    /// Immersive chrome — session only (not persisted).
    var immersive = false

    /// Japanese manga style: left side / ← goes to the next page.
    var rightToLeft: Bool {
        didSet { UserDefaults.standard.set(rightToLeft, forKey: Keys.rightToLeft) }
    }

    private init() {
        rightToLeft = UserDefaults.standard.bool(forKey: Keys.rightToLeft)
    }

    func toggleImmersive() {
        immersive.toggle()
    }

    func exitImmersive() {
        immersive = false
    }
}
