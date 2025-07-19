#if os(macOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func scrollViewConfigurator(_ configurator: @escaping ScrollViewConfigurator) -> Self {
        Self(model: self.model,
             scrollViewConfigurator: configurator,
             playerViewConfigurator: self.playerViewConfigurator,
             onPresentationSizeChange: self.onPresentationSizeChange,
             onTap: self.onTap,
             menuContent: self.menuContent)
    }

    func playerViewConfigurator(_ configurator: @escaping PlayerViewConfigurator) -> Self {
        Self(model: self.model,
             scrollViewConfigurator: self.scrollViewConfigurator,
             playerViewConfigurator: configurator,
             onPresentationSizeChange: self.onPresentationSizeChange,
             onTap: self.onTap,
             menuContent: self.menuContent)
    }

    func onPresentationSizeChange(_ action: @escaping PresentationSizeAction) -> Self {
        Self(model: self.model,
             scrollViewConfigurator: self.scrollViewConfigurator,
             playerViewConfigurator: self.playerViewConfigurator,
             onPresentationSizeChange: action,
             onTap: self.onTap,
             menuContent: self.menuContent)
    }
}
#endif
