#if os(iOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func scrollViewConfigurator(_ configurator: @escaping ScrollViewConfigurator) -> Self {
        Self(model: self.model, panGesture: self.panGesture, scrollViewConfigurator: configurator, contextMenuProvider: self.contextMenuProvider, tapAction: self.tapAction)
    }

    func contextMenuProvider(_ provider: @escaping ContextMenuProvider) -> Self {
        Self(model: self.model, panGesture: self.panGesture, scrollViewConfigurator: self.scrollViewConfigurator, contextMenuProvider: provider, tapAction: self.tapAction)
    }

    func panGesture(_ gesture: PDVideoPlayerPanGesture) -> Self {
        Self(model: self.model, panGesture: gesture, scrollViewConfigurator: self.scrollViewConfigurator, contextMenuProvider: self.contextMenuProvider, tapAction: self.tapAction)
    }
}
#endif
