#if os(iOS) || os(macOS)
import SwiftUI

/// Overlay indicating the temporary fast-forward playback speed.
public struct FastForwardIndicatorView: View {
    @Environment(PDPlayerModel.self) private var model
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor

    public init() {}

    public var body: some View {
        ZStack {
            if model.isLongpress {
                overlay
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.12), value: model.isLongpress)
    }

    private var overlay: some View {
        HStack(spacing: 4) {
            Text("\(min(2.0, model.originalRate * 2.0), specifier: "%.1f")x")
            Image(systemName: "forward.fill")
                .imageScale(.small)
        }
        .fontDesign(.rounded)
        .fontWeight(.semibold)
        .font(.callout)
        .foregroundStyle(foregroundColor)
        .opacity(0.8)
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif
