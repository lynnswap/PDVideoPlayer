import Foundation

#if os(iOS)
/// Gesture types for closing the player.
public enum PDVideoPlayerCloseGesture {
    /// Drag with rotation gesture.
    case rotation
    /// Drag only up and down.
    case vertical
    /// Disable the close gesture.
    case none
}
#endif
