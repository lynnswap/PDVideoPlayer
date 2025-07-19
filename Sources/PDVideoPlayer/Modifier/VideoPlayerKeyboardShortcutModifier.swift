#if os(iOS) || os(macOS)
import SwiftUI

/// Provides keyboard shortcuts for common playback controls.
public struct VideoPlayerKeyboardShortcutModifier: ViewModifier {
    public var model:PDPlayerModel

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Button("") { model.togglePlay() }
                        .keyboardShortcut(.space, modifiers: [])
                    Button("") { model.stepFrames(by: -1) }
                        .keyboardShortcut(.leftArrow, modifiers: [])
                    Button("") { model.stepFrames(by: 1) }
                        .keyboardShortcut(.rightArrow, modifiers: [])
                    
                    Button("") { model.cycleRewindRate() }
                        .keyboardShortcut("j", modifiers: [])
                    Button("") { model.pause() }
                        .keyboardShortcut("k", modifiers: [])
                    Button("") { model.cycleForwardRate() }
                        .keyboardShortcut("l", modifiers: [])
                }
                .buttonStyle(.plain)
                .foregroundStyle(.clear)
            )
    }
}

extension View {
    /// Adds keyboard shortcuts for controlling playback.
    public func videoPlayerKeyboardShortcuts(
        _ model:PDPlayerModel
    ) -> some View {
        modifier(VideoPlayerKeyboardShortcutModifier(model:model))
    }
}
#endif
