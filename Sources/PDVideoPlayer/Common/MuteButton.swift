#if os(iOS) || os(macOS)
import SwiftUI

/// A button that toggles the muted state of the video player.
public struct MuteButton: View {
    @Environment(\.videoPlayerIsMuted) private var isMutedBinding
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor

    public init() {}

    public var body: some View {
        Button {
            isMutedBinding?.wrappedValue.toggle()
        } label: {
            ZStack {
                Color.clear
                Image(systemName: "speaker")
                    .symbolVariant((isMutedBinding?.wrappedValue ?? false) ? .slash.fill : .fill)
                    .adaptiveSymbolReplaceTransition()
            }
            .contentShape(Rectangle())
        }
        .foregroundStyle(foregroundColor)
        .fontDesign(.rounded)
        .opacity(0.8)
        .buttonStyle(.plain)
    }
}
#endif
