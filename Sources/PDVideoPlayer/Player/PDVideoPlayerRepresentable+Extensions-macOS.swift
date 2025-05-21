#if os(macOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func playerViewConfigurator(_ configurator: @escaping PlayerViewConfigurator) -> Self {
        Self(model: self.model, playerViewConfigurator: configurator, resizeAction: self.resizeAction, menuContent: self.menuContent)
    }

    func resizeAction(_ action: @escaping ResizeAction) -> Self {
        Self(model: self.model, playerViewConfigurator: self.playerViewConfigurator, resizeAction: action, menuContent: self.menuContent)
    }

    func windowDragEnabled(_ enabled: Bool = true) -> Self {
        let configurator = self.playerViewConfigurator
        let newConfigurator: PlayerViewConfigurator = { view in
            configurator?(view)
            if let customView = view as? CustomAVPlayerView {
                customView.enableWindowDrag = enabled
            }
        }
        return Self(model: self.model, playerViewConfigurator: newConfigurator, resizeAction: self.resizeAction, menuContent: self.menuContent)
    }
}
#endif
