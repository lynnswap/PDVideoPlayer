#if os(macOS)
import AppKit

/// NSScrollView used in macOS video player.
/// Disables scrolling when magnification is at the minimum level.
class PlayerScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        if magnification <= minMagnification {
            return
        }
        super.scrollWheel(with: event)
    }
}
#endif
