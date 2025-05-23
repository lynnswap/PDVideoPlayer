#if os(iOS) || os(macOS)
import SwiftUI
import AVFoundation

/// A menu that lets the user choose between available subtitle tracks.
public struct SubtitleMenuView: View {
    @Environment(PDPlayerModel.self) private var model
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor

    public init() {}

    public var body: some View {
        Menu {
            Button { model.selectSubtitle(nil) } label: {
                label(for: nil)
            }
            ForEach(model.subtitleOptions, id: \.self) { option in
                Button { model.selectSubtitle(option) } label: {
                    label(for: option)
                }
            }
        } label: {
            ZStack {
                Color.clear
                Image(systemName: "captions.bubble.fill")
                    .foregroundStyle(foregroundColor)
                    .fontDesign(.rounded)
                    .opacity(0.8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func label(for option: AVMediaSelectionOption?) -> some View {
        let title = option?.displayName ?? "Off"
        if model.selectedSubtitle == option {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }
}
#endif
