#if os(iOS) || os(macOS)
import SwiftUI

public extension View {
    /// Applies `glassEffect` when supported by the OS.
    @ViewBuilder
    func glassEffectIfAvailable() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }
}
#endif
