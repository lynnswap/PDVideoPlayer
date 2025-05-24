#if os(iOS) || os(macOS)
import SwiftUI

public extension PDVideoPlayer {
    func isMuted(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.isMuted = binding
        return copy
    }
    
    func onClose(_ action: VideoPlayerCloseAction) -> Self {
        var copy = self
        copy.onClose = action
        return copy
    }

    func onClose(_ action: @escaping (CGFloat) -> Void) -> Self {
        var copy = self
        copy.onClose = VideoPlayerCloseAction(action)
        return copy
    }

    func onLongPress(_ action: VideoPlayerLongpressAction) -> Self {
        var copy = self
        copy.onLongPress = action
        return copy
    }

    func onLongPress(_ action: @escaping (Bool) -> Void) -> Self {
        var copy = self
        copy.onLongPress = VideoPlayerLongpressAction(action)
        return copy
    }

    func playerForegroundColor(_ color: Color) -> Self {
        var copy = self
        copy.foregroundColor = color
        return copy
    }

#if os(macOS)
    /// Allows the window to move when dragging on the player view.
    func windowDraggable(_ value: Bool = true) -> Self {
        var copy = self
        copy.windowDraggable = value
        return copy
    }
#endif
}

#endif
