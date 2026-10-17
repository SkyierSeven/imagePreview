import SwiftUI

struct ShortcutSettingsView: View {
    @Bindable var settings: ShortcutSettings
    @Environment(\.dismiss) private var dismiss

    private enum CaptureTarget {
        case previous
        case next
    }

    @State private var capturing: CaptureTarget?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("自定义切图快捷键")
                .font(.headline)

            Text("方向键 ↑ ↓ ← → 始终有效，不会被覆盖。这里可再设一组额外快捷键。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            grid

            if capturing != nil {
                Text("请按下新的快捷键…（Esc 取消）")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            HStack {
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress { press in
            guard let target = capturing else { return .ignored }
            if press.key == .escape {
                capturing = nil
                return .handled
            }
            guard let stroke = KeyStroke.from(press: press) else {
                return .handled
            }
            switch target {
            case .previous: settings.previous = stroke
            case .next: settings.next = stroke
            }
            capturing = nil
            return .handled
        }
    }

    private var grid: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
            GridRow {
                Text("上一张")
                shortcutButton(
                    title: settings.previous?.displayName ?? "未设置",
                    isCapturing: capturing == .previous
                ) {
                    capturing = .previous
                }
                Button("清除") { settings.previous = nil }
                    .disabled(settings.previous == nil)
            }
            GridRow {
                Text("下一张")
                shortcutButton(
                    title: settings.next?.displayName ?? "未设置",
                    isCapturing: capturing == .next
                ) {
                    capturing = .next
                }
                Button("清除") { settings.next = nil }
                    .disabled(settings.next == nil)
            }
        }
    }

    private func shortcutButton(title: String, isCapturing: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(isCapturing ? "按下按键…" : title)
                .frame(minWidth: 120)
        }
        .buttonStyle(.bordered)
    }
}
