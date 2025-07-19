#if os(iOS)
import SwiftUI

@MainActor
public extension PDVideoPlayerProxy {
    func player(
        scrollViewConfigurator: PDVideoPlayerRepresentable.ScrollViewConfigurator? = nil,
        contextMenuProvider: PDVideoPlayerRepresentable.ContextMenuProvider? = nil,
        onTap: VideoPlayerTapAction? = nil
    ) -> PDVideoPlayerRepresentable {
        var view = self.player
        if let scrollViewConfigurator {
            view = view.scrollViewConfigurator(scrollViewConfigurator)
        }
        if let contextMenuProvider {
            view = view.contextMenuProvider(contextMenuProvider)
        }
        if let onTap {
            view = view.onTap(onTap)
        }
        return view
    }
}
#elseif os(macOS)
import SwiftUI

@MainActor
public extension PDVideoPlayerProxy {
    func player(
        scrollViewConfigurator: PDVideoPlayerRepresentable<MenuContent>.ScrollViewConfigurator? = nil,
        playerViewConfigurator: PDVideoPlayerRepresentable<MenuContent>.PlayerViewConfigurator? = nil,
        onTap: VideoPlayerTapAction? = nil
    ) -> PDVideoPlayerRepresentable<MenuContent> {
        var view = self.player
        if let scrollViewConfigurator {
            view = view.scrollViewConfigurator(scrollViewConfigurator)
        }
        if let playerViewConfigurator {
            view = view.playerViewConfigurator(playerViewConfigurator)
        }
        if let onTap {
            view = view.onTap(onTap)
        }
        return view
    }
}
#endif
