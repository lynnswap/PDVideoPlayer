#if os(iOS)
import SwiftUI

@MainActor
public extension PDVideoPlayerProxy {
    func player(
        panGesture: PDVideoPlayerPanGesture? = nil,
        scrollViewConfigurator: PDVideoPlayerRepresentable.ScrollViewConfigurator? = nil,
        contextMenuProvider: PDVideoPlayerRepresentable.ContextMenuProvider? = nil,
        onTap: VideoPlayerTapAction? = nil
    ) -> PDVideoPlayerRepresentable {
        var view = self.player
        if let panGesture {
            view = view.panGesture(panGesture)
        }
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
#endif
