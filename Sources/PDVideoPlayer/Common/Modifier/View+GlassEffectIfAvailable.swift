//
//  View+GlassEffectIfAvailable.swift
//  PDVideoPlayer
//
//  Created by lynnswap on 2025/07/03.
//

import SwiftUI
extension View {
    func glassEffectIfAvailable() -> some View {
#if swift(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) {
            return self.glassEffect()
        } else {
            return self
        }
#else
        return self
#endif
    }
}
