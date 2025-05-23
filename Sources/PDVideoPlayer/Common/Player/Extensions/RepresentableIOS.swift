#if os(iOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func scrollViewConfigurator(_ configurator: @escaping ScrollViewConfigurator) -> Self {
        Self(model: self.model, closeGesture: self.closeGesture, scrollViewConfigurator: configurator, contextMenuProvider: self.contextMenuProvider, onTap: self.onTap)
    }

    func contextMenuProvider(_ provider: @escaping ContextMenuProvider) -> Self {
        Self(model: self.model, closeGesture: self.closeGesture, scrollViewConfigurator: self.scrollViewConfigurator, contextMenuProvider: provider, onTap: self.onTap)
    }

    func closeGesture(_ gesture: PDVideoPlayerCloseGesture) -> Self {
        Self(model: self.model, closeGesture: gesture, scrollViewConfigurator: self.scrollViewConfigurator, contextMenuProvider: self.contextMenuProvider, onTap: self.onTap)
    }
}
#endif
