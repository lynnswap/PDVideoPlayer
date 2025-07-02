import SwiftUI

extension View {
    func glassEffectIfAvailable() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            return self.glassEffect()
        } else {
            return self
        }
    }
}

