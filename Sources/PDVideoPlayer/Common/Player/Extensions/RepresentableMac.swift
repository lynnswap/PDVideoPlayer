#if os(macOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func playerViewConfigurator(_ configurator: @escaping PlayerViewConfigurator) -> Self {
        Self(model: self.model, playerViewConfigurator: configurator, onResize: self.onResize, onTap: self.onTap, menuContent: self.menuContent)
    }

    func onResize(_ action: @escaping ResizeAction) -> Self {
        Self(model: self.model, playerViewConfigurator: self.playerViewConfigurator, onResize: action, onTap: self.onTap, menuContent: self.menuContent)
    }
}
#endif
