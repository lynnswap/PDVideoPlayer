#if os(macOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func playerViewConfigurator(_ configurator: @escaping PlayerViewConfigurator) -> Self {
        Self(player: self.player, playerViewConfigurator: configurator, resizeAction: self.resizeAction, menuContent: self.menuContent)
    }

    func resizeAction(_ action: @escaping ResizeAction) -> Self {
        Self(player: self.player, playerViewConfigurator: self.playerViewConfigurator, resizeAction: action, menuContent: self.menuContent)
    }
}
#endif
