#if os(iOS) || os(macOS)
import SwiftUI

public extension PDVideoPlayer {
    func isMuted(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.isMuted = binding
        return copy
    }
    
    func closeAction(_ action: VideoPlayerCloseAction) -> Self {
        var copy = self
        copy.closeAction = action
        return copy
    }

    func closeAction(_ action: @escaping (CGFloat) -> Void) -> Self {
        var copy = self
        copy.closeAction = VideoPlayerCloseAction(action)
        return copy
    }

    func longpressAction(_ action: VideoPlayerLongpressAction) -> Self {
        var copy = self
        copy.longpressAction = action
        return copy
    }

    func longpressAction(_ action: @escaping (Bool) -> Void) -> Self {
        var copy = self
        copy.longpressAction = VideoPlayerLongpressAction(action)
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

#if os(iOS)
public extension PDVideoPlayer {
    func panGesture(_ gesture: PDVideoPlayerPanGesture) -> Self {
        var copy = self
        copy.panGesture = gesture
        return copy
    }
}
#endif
#endif
