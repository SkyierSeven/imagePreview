import Foundation

enum DisplayMode: String, CaseIterable, Identifiable, Sendable {
    case fit
    case fill
    case actual
    case stretch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fit: return "适应窗口"
        case .fill: return "填满窗口"
        case .actual: return "实际大小"
        case .stretch: return "拉伸填满"
        }
    }

    var shortcutHint: String {
        switch self {
        case .fit: return "0"
        case .fill: return "F"
        case .actual: return "1"
        case .stretch: return "S"
        }
    }
}
