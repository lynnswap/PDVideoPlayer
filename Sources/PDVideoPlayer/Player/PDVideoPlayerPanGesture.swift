import Foundation

#if os(iOS)
/// Gesture types for closing the player.
public enum PDVideoPlayerPanGesture {
    /// Drag with rotation gesture.
    case rotation
    /// Drag only up and down.
    case vertical
    /// Disable pan gesture.
    case none
}
#endif
