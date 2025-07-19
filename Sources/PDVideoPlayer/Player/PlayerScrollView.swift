#if os(macOS)
import AppKit

/// NSScrollView used in macOS video player.
/// Disables scrolling when magnification is at the minimum level.
public class PlayerScrollView: NSScrollView {
    public override func scrollWheel(with event: NSEvent) {
        if magnification <= minMagnification {
            nextResponder?.scrollWheel(with: event)
            return
        }
        super.scrollWheel(with: event)
    }
}
#endif
