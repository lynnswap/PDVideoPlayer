import SwiftUI

/// Closure wrapper that can be invoked like a function.
public struct VideoPlayerCloseAction {
    let action: (CGFloat) -> Void
    public init(_ action: @escaping (CGFloat) -> Void) {
        self.action = action
    }
    public func callAsFunction(_ duration: CGFloat) {
        action(duration)
    }
}

/// Environment entries defined with the new `@Entry` macro available in Xcode 16.
/// This replaces the old `EnvironmentKey` structs.

public struct VideoPlayerLongpressAction {
    let action: (Bool) -> Void
    public init(_ action: @escaping (Bool) -> Void) {
        self.action = action
    }
    public func callAsFunction(_ value: Bool) {
        action(value)
    }
}

public struct VideoPlayerTapAction {
    let action: (Bool) -> Void
    public init(_ action: @escaping (Bool) -> Void) {
        self.action = action
    }
    public func callAsFunction(_ isInsideVideo: Bool) {
        action(isInsideVideo)
    }
}

extension EnvironmentValues {
    /// Xcode 16 の `@Entry` マクロを利用した環境値の定義
    @Entry var videoPlayerOnClose: VideoPlayerCloseAction? = nil
    @Entry var videoPlayerPlaybackSpeed: Binding<PlaybackSpeed>? = nil
    @Entry var videoPlayerControlsVisible: Binding<Bool>? = nil
    @Entry var videoPlayerOnLongPress: VideoPlayerLongpressAction? = nil
    @Entry var videoPlayerForegroundColor: Color = .white
#if os(macOS)
    @Entry var videoPlayerSliderKnobSize: CGFloat = 12
#else
    @Entry var videoPlayerSliderKnobSize: CGFloat = 6
#endif
}

