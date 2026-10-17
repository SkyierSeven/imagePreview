import Foundation
import Observation
import SwiftUI

/// Extra user-defined shortcuts for prev/next.
/// Built-in arrow keys (↑↓←→) always work and are not stored here.
@MainActor
@Observable
final class ShortcutSettings {
    static let shared = ShortcutSettings()

    private enum Keys {
        static let previous = "shortcut.custom.previous"
        static let next = "shortcut.custom.next"
    }

    var previous: KeyStroke? {
        didSet { persist(previous, key: Keys.previous) }
    }

    var next: KeyStroke? {
        didSet { persist(next, key: Keys.next) }
    }

    private init() {
        previous = Self.load(Keys.previous)
        next = Self.load(Keys.next)
    }

    func matchesPrevious(_ press: KeyPress) -> Bool {
        previous?.matches(press) == true
    }

    func matchesNext(_ press: KeyPress) -> Bool {
        next?.matches(press) == true
    }

    private func persist(_ stroke: KeyStroke?, key: String) {
        if let stroke, let data = try? JSONEncoder().encode(stroke) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private static func load(_ key: String) -> KeyStroke? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(KeyStroke.self, from: data)
    }
}

struct KeyStroke: Codable, Equatable, Sendable {
    var character: String
    var command: Bool
    var shift: Bool
    var option: Bool
    var control: Bool

    var displayName: String {
        var parts: [String] = []
        if control { parts.append("⌃") }
        if option { parts.append("⌥") }
        if shift { parts.append("⇧") }
        if command { parts.append("⌘") }
        parts.append(Self.symbol(for: character))
        return parts.joined()
    }

    func matches(_ press: KeyPress) -> Bool {
        let mods = press.modifiers
        guard mods.contains(.command) == command else { return false }
        guard mods.contains(.shift) == shift else { return false }
        guard mods.contains(.option) == option else { return false }
        guard mods.contains(.control) == control else { return false }
        let pressed = Self.normalize(press.characters.lowercased())
        return pressed == character
    }

    static func from(press: KeyPress) -> KeyStroke? {
        // Don't capture bare arrows — those stay built-in.
        if press.key == .leftArrow || press.key == .rightArrow
            || press.key == .upArrow || press.key == .downArrow
        {
            return nil
        }
        let raw = press.characters.lowercased()
        guard !raw.isEmpty else { return nil }
        let mods = press.modifiers
        return KeyStroke(
            character: normalize(raw),
            command: mods.contains(.command),
            shift: mods.contains(.shift),
            option: mods.contains(.option),
            control: mods.contains(.control)
        )
    }

    private static func normalize(_ s: String) -> String {
        if s == " " { return "space" }
        return s
    }

    private static func symbol(for character: String) -> String {
        switch character {
        case "space": return "空格"
        case "\r": return "↩"
        case "\u{1b}": return "⎋"
        case "\t": return "⇥"
        default: return character.uppercased()
        }
    }
}
