#if os(iOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func scrollViewConfigurator(_ configurator: @escaping ScrollViewConfigurator) -> Self {
        Self(model: self.model,
             closeGesture: self.closeGesture,
             scrollViewConfigurator: configurator,
             contextMenuProvider: self.contextMenuProvider,
             onPresentationSizeChange: self.onPresentationSizeChange,
             onTap: self.onTap)
    }

    func contextMenuProvider(_ provider: @escaping ContextMenuProvider) -> Self {
        Self(model: self.model,
             closeGesture: self.closeGesture,
             scrollViewConfigurator: self.scrollViewConfigurator,
             contextMenuProvider: provider,
             onPresentationSizeChange: self.onPresentationSizeChange,
             onTap: self.onTap)
    }

    func closeGesture(_ gesture: PDVideoPlayerCloseGesture) -> Self {
        Self(model: self.model,
             closeGesture: gesture,
             scrollViewConfigurator: self.scrollViewConfigurator,
             contextMenuProvider: self.contextMenuProvider,
             onPresentationSizeChange: self.onPresentationSizeChange,
             onTap: self.onTap)
    }

    func onPresentationSizeChange(_ action: @escaping PresentationSizeAction) -> Self {
        Self(model: self.model,
             closeGesture: self.closeGesture,
             scrollViewConfigurator: self.scrollViewConfigurator,
             contextMenuProvider: self.contextMenuProvider,
             onPresentationSizeChange: action,
             onTap: self.onTap)
    }
}
#endif
