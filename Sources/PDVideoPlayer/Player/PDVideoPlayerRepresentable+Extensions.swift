#if os(iOS)
import SwiftUI

extension PDVideoPlayerRepresentable {
    func scrollViewConfigurator(_ configurator: @escaping ScrollViewConfigurator) -> Self {
        Self(model: self.model, scrollViewConfigurator: configurator, contextMenuProvider: self.contextMenuProvider)
    }

    func contextMenuProvider(_ provider: @escaping ContextMenuProvider) -> Self {
        Self(model: self.model, scrollViewConfigurator: self.scrollViewConfigurator, contextMenuProvider: provider)
    }
}
#endif
