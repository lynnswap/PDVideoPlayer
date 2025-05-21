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

private struct VideoPlayerCloseActionKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: VideoPlayerCloseAction? = nil
}
private struct VideoPlayerIsMutedKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
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

private struct VideoPlayerLongpressActionKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: VideoPlayerLongpressAction? = nil
}

private struct VideoPlayerForegroundColorKey: EnvironmentKey {
    static let defaultValue: Color = .white
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
    var videoPlayerControlsVisible: Binding<Bool>? {
        get { self[VideoPlayerControlsVisibleKey.self] }
        set { self[VideoPlayerControlsVisibleKey.self] = newValue }
    }
    var videoPlayerLongpressAction: VideoPlayerLongpressAction? {
        get { self[VideoPlayerLongpressActionKey.self] }
        set { self[VideoPlayerLongpressActionKey.self] = newValue }
    }
    var videoPlayerForegroundColor: Color {
        get { self[VideoPlayerForegroundColorKey.self] }
        set { self[VideoPlayerForegroundColorKey.self] = newValue }
    }
}

public extension View {
    func videoPlayerForegroundColor(_ color: Color) -> some View {
        environment(\.videoPlayerForegroundColor, color)
    }
}
