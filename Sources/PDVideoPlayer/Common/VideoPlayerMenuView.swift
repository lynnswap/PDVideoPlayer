#if os(iOS)
import SwiftUI

/// A menu containing subtitle and playback speed controls.
public struct VideoPlayerMenuView<MenuContent: View>: View {
    private let menuContent: () -> MenuContent
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor

    public init(@ViewBuilder menuContent: @escaping () -> MenuContent) {
        self.menuContent = menuContent
    }

    public var body: some View {
        Menu {
            SubtitleMenuView()
                .pickerStyle(.menu)
                .menuActionDismissBehavior(.disabled)
            PlaybackSpeedMenuView()
                .pickerStyle(.menu)
                .menuActionDismissBehavior(.disabled)
            Divider()
            menuContent()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .contentShape(Rectangle())
                Image(systemName: "ellipsis.circle")
                    .font(.callout)
                    .foregroundStyle(foregroundColor)
                    .opacity(0.8)
                    .padding(.top, 12)
            }
            .frame(width: 60, height: 60)
            .padding(.trailing)
            .padding(.leading, 4)
            .contentShape(Rectangle())
        }
    }
}
#endif
