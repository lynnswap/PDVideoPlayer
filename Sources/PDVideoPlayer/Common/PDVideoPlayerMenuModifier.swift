#if os(iOS) || os(macOS)
import SwiftUI

extension PDVideoPlayer {
    // Internal initializer used by the menu modifier
    init<OldMenu: View>(
        base: PDVideoPlayer<OldMenu, Content>,
        menu: @escaping () -> MenuContent
    ) where OldMenu == EmptyView {
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
        self.content = { proxy in
            // call original content by dropping menu information
            base.content(proxy.withoutMenu())
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
