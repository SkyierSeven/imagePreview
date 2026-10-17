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
        case .fill: return ""
        case .actual: return "1"
        case .stretch: return "S"
        }
    }

    var tip: String {
        switch self {
        case .fit: return "适应窗口：完整显示整张图（快捷键 0）"
        case .fill: return "填满窗口：铺满窗口，可能裁切边缘"
        case .actual: return "实际大小：按 1:1 像素显示（快捷键 1）"
        case .stretch: return "拉伸填满：忽略比例拉满窗口（快捷键 S）"
        }
    }

    var symbolName: String {
        switch self {
        case .fit: return "arrow.down.right.and.arrow.up.left"
        case .fill: return "arrow.up.left.and.arrow.down.right"
        case .actual: return "1.magnifyingglass"
        case .stretch: return "rectangle.arrowtriangle.2.outward"
        }
    }
}
