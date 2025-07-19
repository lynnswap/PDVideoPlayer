#if os(iOS) || os(macOS)
import SwiftUI

/// Sets the knob size for `VideoPlayerControlView`.
struct VideoPlayerKnobSizeModifier: ViewModifier {
    let size: CGFloat
    func body(content: Content) -> some View {
        content.environment(\.videoPlayerSliderKnobSize, size)
    }
}

public extension VideoPlayerControlView {
    /// Adjusts the size of the slider knob.
    func knobSize(_ size: CGFloat) -> some View {
        modifier(VideoPlayerKnobSizeModifier(size: size))
    }
}
#endif
