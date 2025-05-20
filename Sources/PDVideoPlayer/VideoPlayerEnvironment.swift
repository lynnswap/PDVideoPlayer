import SwiftUI

/// Closure wrapper that can be invoked like a function.
public struct VideoPlayerCloseAction {
    let action: () -> Void
    public init(_ action: @escaping () -> Void) {
        self.action = action
    }
    public func callAsFunction() {
        action()
    }
}

private struct VideoPlayerCloseActionKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: VideoPlayerCloseAction? = nil
}
private struct VideoPlayerIsMutedKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}
private struct VideoPlayerIsLongpressKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}
private struct VideoPlayerControlsVisibleKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}
private struct VideoPlayerOriginalRateKey: EnvironmentKey {
    static let defaultValue: Binding<Float>? = nil
}

public extension EnvironmentValues {
    var videoPlayerCloseAction: VideoPlayerCloseAction? {
        get { self[VideoPlayerCloseActionKey.self] }
        set { self[VideoPlayerCloseActionKey.self] = newValue }
    }
    var videoPlayerIsMuted: Binding<Bool>? {
        get { self[VideoPlayerIsMutedKey.self] }
        set { self[VideoPlayerIsMutedKey.self] = newValue }
    }
    var videoPlayerIsLongpress: Binding<Bool>? {
        get { self[VideoPlayerIsLongpressKey.self] }
        set { self[VideoPlayerIsLongpressKey.self] = newValue }
    }
    var videoPlayerControlsVisible: Binding<Bool>? {
        get { self[VideoPlayerControlsVisibleKey.self] }
        set { self[VideoPlayerControlsVisibleKey.self] = newValue }
    }
    var videoPlayerOriginalRate: Binding<Float>? {
        get { self[VideoPlayerOriginalRateKey.self] }
        set { self[VideoPlayerOriginalRateKey.self] = newValue }
    }
}
