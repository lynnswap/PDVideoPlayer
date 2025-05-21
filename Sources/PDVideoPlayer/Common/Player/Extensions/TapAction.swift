import SwiftUI

public extension PDVideoPlayerRepresentable {
    func tapAction(_ action: VideoPlayerTapAction) -> Self {
        #if os(iOS)
        Self(model: self.model,
             panGesture: self.panGesture,
             scrollViewConfigurator: self.scrollViewConfigurator,
             contextMenuProvider: self.contextMenuProvider,
             tapAction: action)
        #elseif os(macOS)
        Self(model: self.model,
             playerViewConfigurator: self.playerViewConfigurator,
             resizeAction: self.resizeAction,
             tapAction: action,
             menuContent: self.menuContent)
        #else
        self
        #endif
    }

    func tapAction(_ action: @escaping () -> Void) -> Self {
        tapAction(VideoPlayerTapAction(action))
    }
}

