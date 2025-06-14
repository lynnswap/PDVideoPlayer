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

private struct VideoPlayerOnCloseKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: VideoPlayerCloseAction? = nil
}
private struct VideoPlayerIsMutedKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}
private struct VideoPlayerPlaybackSpeedKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: Binding<PlaybackSpeed>? = nil
}
private struct VideoPlayerControlsVisibleKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

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

private struct VideoPlayerOnLongPressKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: VideoPlayerLongpressAction? = nil
}

private struct VideoPlayerForegroundColorKey: EnvironmentKey {
    static let defaultValue: Color = .white
}

#if os(macOS)
private struct VideoPlayerSliderKnobSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 12
}
#else
private struct VideoPlayerSliderKnobSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 6
}
#endif

public extension EnvironmentValues {
    var videoPlayerOnClose: VideoPlayerCloseAction? {
        get { self[VideoPlayerOnCloseKey.self] }
        set { self[VideoPlayerOnCloseKey.self] = newValue }
    }
    var videoPlayerIsMuted: Binding<Bool>? {
        get { self[VideoPlayerIsMutedKey.self] }
        set { self[VideoPlayerIsMutedKey.self] = newValue }
    }
    var videoPlayerPlaybackSpeed: Binding<PlaybackSpeed>? {
        get { self[VideoPlayerPlaybackSpeedKey.self] }
        set { self[VideoPlayerPlaybackSpeedKey.self] = newValue }
    }
    var videoPlayerOnLongPress: VideoPlayerLongpressAction? {
        get { self[VideoPlayerOnLongPressKey.self] }
        set { self[VideoPlayerOnLongPressKey.self] = newValue }
    }
    var videoPlayerForegroundColor: Color {
        get { self[VideoPlayerForegroundColorKey.self] }
        set { self[VideoPlayerForegroundColorKey.self] = newValue }
    }
    var videoPlayerSliderKnobSize: CGFloat {
        get { self[VideoPlayerSliderKnobSizeKey.self] }
        set { self[VideoPlayerSliderKnobSizeKey.self] = newValue }
    }
}

