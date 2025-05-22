#if os(iOS) || os(macOS)
import SwiftUI

/// Provides keyboard shortcuts for common playback controls.
struct VideoPlayerKeyboardShortcutModifier: ViewModifier {
    @Environment(PDPlayerModel.self) private var model

    func body(content: Content) -> some View {
        content
            .background(
                KeyboardShortcutButtons()
            )
    }

    @ViewBuilder
    private func KeyboardShortcutButtons() -> some View {
        ZStack {
            Button("") { model.togglePlay() }
                .keyboardShortcut(.space, modifiers: [])
            Button("") { model.stepFrames(by: -1) }
                .keyboardShortcut(.leftArrow, modifiers: [])
            Button("") { model.stepFrames(by: 1) }
                .keyboardShortcut(.rightArrow, modifiers: [])
        }
        .buttonStyle(.plain)
        .foregroundStyle(.clear)
    }
}

extension View {
    /// Adds keyboard shortcuts for controlling playback.
    public func videoPlayerKeyboardShortcuts() -> some View {
        modifier(VideoPlayerKeyboardShortcutModifier())
    }
}
#endif
