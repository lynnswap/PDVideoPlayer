import SwiftUI

public extension PDVideoPlayerRepresentable {
    func onTap(_ action: VideoPlayerTapAction) -> Self {
        #if os(iOS)
        Self(model: self.model,
             panGesture: self.panGesture,
             scrollViewConfigurator: self.scrollViewConfigurator,
             contextMenuProvider: self.contextMenuProvider,
             onTap: action)
        #elseif os(macOS)
        Self(model: self.model,
             playerViewConfigurator: self.playerViewConfigurator,
             onPresentationSizeChange: self.onPresentationSizeChange,
             onTap: action,
             menuContent: self.menuContent)
        #else
        self
        #endif
    }

    func onTap(_ action: @escaping (Bool) -> Void) -> Self {
        onTap(VideoPlayerTapAction(action))
    }

    func onTap(_ action: @escaping () -> Void) -> Self {
        onTap { _ in action() }
    }
}

