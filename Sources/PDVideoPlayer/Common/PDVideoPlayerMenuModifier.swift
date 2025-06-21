#if os(iOS) || os(macOS)
import SwiftUI

extension PDVideoPlayer {
    // Internal initializer used by the menu modifier. Only available when the
    // original player had no menu content.
    @MainActor
    init(
        base: PDVideoPlayer<EmptyView, Content>,
        menu: @escaping () -> MenuContent
    ) {
        self.url = base.url
        self.player = base.player
        self.isMuted = base.isMuted
        self.playbackSpeed = base.playbackSpeed
        self.foregroundColor = base.foregroundColor
        self.onClose = base.onClose
        self.onLongPress = base.onLongPress
#if os(macOS)
        self.windowDraggable = base.windowDraggable
#endif
        self.menuContent = menu
        let baseContent: (PDVideoPlayerProxy<MenuContent>) -> Content =
            unsafeBitCast(base.content, to: ((PDVideoPlayerProxy<MenuContent>) -> Content).self)
        self.content = { proxy in
            baseContent(proxy)
        }
    }
}

public extension PDVideoPlayer where MenuContent == EmptyView {
    /// Provides menu content for the player via modifier.
    func menu<NewMenu: View>(
        @ViewBuilder _ builder: @escaping () -> NewMenu
    ) -> PDVideoPlayer<NewMenu, Content> {
        PDVideoPlayer<NewMenu, Content>(base: self, menu: builder)
    }
}
#endif
