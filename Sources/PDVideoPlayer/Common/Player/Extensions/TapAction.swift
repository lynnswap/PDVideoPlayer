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
             onPresentationSizeChange: self.onPresentationSizeChange,
             tapAction: action,
             menuContent: self.menuContent)
        #else
        self
        #endif
    }

    func tapAction(_ action: @escaping (Bool) -> Void) -> Self {
        tapAction(VideoPlayerTapAction(action))
    }

    func tapAction(_ action: @escaping () -> Void) -> Self {
        tapAction { _ in action() }
    }

    /// SwiftUI-style alias for ``tapAction(_:)``.
    func onTap(_ action: VideoPlayerTapAction) -> Self {
        tapAction(action)
    }

    /// SwiftUI-style alias for ``tapAction(_:)``.
    func onTap(_ action: @escaping (Bool) -> Void) -> Self {
        tapAction(action)
    }

    /// SwiftUI-style alias for ``tapAction(_:)``.
    func onTap(_ action: @escaping () -> Void) -> Self {
        tapAction(action)
    }
}

