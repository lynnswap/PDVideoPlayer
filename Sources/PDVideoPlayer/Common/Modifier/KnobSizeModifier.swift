#if os(iOS) || os(macOS)
import SwiftUI

/// Sets the knob size for `VideoPlayerSliderView`.
public struct VideoPlayerKnobSizeModifier: ViewModifier {
    let size: CGFloat
    public func body(content: Content) -> some View {
        content.environment(\.videoPlayerSliderKnobSize, size)
    }
}

public extension VideoPlayerControlView {
    /// Adjusts the knob size of the player's slider.
    func knobSize(_ size: CGFloat) -> some View {
        modifier(VideoPlayerKnobSizeModifier(size: size))
    }
}
#endif
