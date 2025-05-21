#if os(macOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func playerViewConfigurator(_ configurator: @escaping PlayerViewConfigurator) -> Self {
        Self(model: self.model, playerViewConfigurator: configurator, resizeAction: self.resizeAction, tapAction: self.tapAction, menuContent: self.menuContent)
    }

    func resizeAction(_ action: @escaping ResizeAction) -> Self {
        Self(model: self.model, playerViewConfigurator: self.playerViewConfigurator, resizeAction: action, tapAction: self.tapAction, menuContent: self.menuContent)
    }
}
#endif
