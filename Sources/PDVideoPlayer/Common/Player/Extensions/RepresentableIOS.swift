#if os(iOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func scrollViewConfigurator(_ configurator: @escaping ScrollViewConfigurator) -> Self {
        Self(model: self.model,
             panGesture: self.panGesture,
             scrollViewConfigurator: configurator,
             contextMenuProvider: self.contextMenuProvider,
             onPresentationSizeChange: self.onPresentationSizeChange,
             onTap: self.onTap)
    }

    func contextMenuProvider(_ provider: @escaping ContextMenuProvider) -> Self {
        Self(model: self.model,
             panGesture: self.panGesture,
             scrollViewConfigurator: self.scrollViewConfigurator,
             contextMenuProvider: provider,
             onPresentationSizeChange: self.onPresentationSizeChange,
             onTap: self.onTap)
    }

    func panGesture(_ gesture: PDVideoPlayerPanGesture) -> Self {
        Self(model: self.model,
             panGesture: gesture,
             scrollViewConfigurator: self.scrollViewConfigurator,
             contextMenuProvider: self.contextMenuProvider,
             onPresentationSizeChange: self.onPresentationSizeChange,
             onTap: self.onTap)
    }

    func onPresentationSizeChange(_ action: @escaping PresentationSizeAction) -> Self {
        Self(model: self.model,
             panGesture: self.panGesture,
             scrollViewConfigurator: self.scrollViewConfigurator,
             contextMenuProvider: self.contextMenuProvider,
             onPresentationSizeChange: action,
             onTap: self.onTap)
    }
}
#endif
