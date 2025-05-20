#if os(iOS)
import SwiftUI

extension PDVideoPlayerProxy {
    func player(
        scrollViewConfigurator: PDVideoPlayerRepresentable.ScrollViewConfigurator? = nil,
        contextMenuProvider: PDVideoPlayerRepresentable.ContextMenuProvider? = nil
    ) -> PDVideoPlayerRepresentable {
        var view = self.player
        if let scrollViewConfigurator {
            view = view.scrollViewConfigurator(scrollViewConfigurator)
        }
        if let contextMenuProvider {
            view = view.contextMenuProvider(contextMenuProvider)
        }
        return view
    }
}
#endif
