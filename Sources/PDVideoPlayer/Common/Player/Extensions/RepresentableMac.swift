#if os(macOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func playerViewConfigurator(_ configurator: @escaping PlayerViewConfigurator) -> Self {
        Self(model: self.model, playerViewConfigurator: configurator, onPresentationSizeChange: self.onPresentationSizeChange, tapAction: self.tapAction, menuContent: self.menuContent)
    }

    func onPresentationSizeChange(_ action: @escaping PresentationSizeAction) -> Self {
        Self(model: self.model, playerViewConfigurator: self.playerViewConfigurator, onPresentationSizeChange: action, tapAction: self.tapAction, menuContent: self.menuContent)
    }
}
#endif
