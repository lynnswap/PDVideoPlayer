#if os(iOS) || os(macOS)
import SwiftUI

/// Sets the knob size for `VideoPlayerSliderView`.
public struct VideoPlayerKnobSizeModifier: ViewModifier {
    let size: CGFloat
    public func body(content: Content) -> some View {
        content.environment(\.videoPlayerSliderKnobSize, size)
    }
}

public extension PDVideoPlayer {
    /// Adjusts the knob size of the player's slider.
    func knobSize(_ size: CGFloat) -> Self {
        var copy = self
        copy.sliderKnobSize = size
        return copy
    }
}
#endif
