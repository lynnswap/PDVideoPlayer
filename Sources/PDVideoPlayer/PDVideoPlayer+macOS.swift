#if os(macOS)
import SwiftUI
import AVKit

/// A lightweight container for playing videos on macOS.
public struct PDVideoPlayer<MenuContent: View>: View {
    private var player: AVPlayer
    private let menuContent: () -> MenuContent

    /// Creates a player from a URL.
    public init(
        url: URL,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.player = AVPlayer(url: url)
        self.menuContent = menuContent
    }

    /// Creates a player from an existing AVPlayer instance.
    public init(
        player: AVPlayer,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.player = player
        self.menuContent = menuContent
    }

    public var body: some View {
        PDVideoPlayerRepresentable(
            player: player,
            menuContent: menuContent
        )
    }
}

public extension PDVideoPlayer where MenuContent == EmptyView {
    /// Convenience initializer when no menu content is provided.
    init(url: URL) {
        self.init(url: url, menuContent: { EmptyView() })
    }

    /// Convenience initializer when no menu content is provided.
    init(player: AVPlayer) {
        self.init(player: player, menuContent: { EmptyView() })
    }
}
#endif
