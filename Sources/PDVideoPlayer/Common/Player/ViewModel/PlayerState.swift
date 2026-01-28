import SwiftUI

public struct PlayerState {
    public var isPlaying: Bool
    public var currentTime: Double
    public var duration: Double
    public var isTracking: Bool
    public var isScrubbing: Bool
    public var isBuffering: Bool
    public var showBufferingIndicator: Bool
    public var playbackSpeed: PlaybackSpeed
    public var originalRate: Float

#if os(iOS)
    public var isLooping: Bool
    public var doubleTapCount: Int
    public var doubleTapBaseTime: Double
    public var doubleTapDirection: SkipDirection?
    public var isLongpress: Bool
#elseif os(macOS)
    public var windowDraggable: Bool
#endif

    public static var `default`: PlayerState {
#if os(iOS)
        PlayerState(
            isPlaying: false,
            currentTime: 0,
            duration: 0,
            isTracking: false,
            isScrubbing: false,
            isBuffering: false,
            showBufferingIndicator: false,
            playbackSpeed: .x1_0,
            originalRate: 1.0,
            isLooping: true,
            doubleTapCount: 0,
            doubleTapBaseTime: 0,
            doubleTapDirection: nil,
            isLongpress: false
        )
#elseif os(macOS)
        PlayerState(
            isPlaying: false,
            currentTime: 0,
            duration: 0,
            isTracking: false,
            isScrubbing: false,
            isBuffering: false,
            showBufferingIndicator: false,
            playbackSpeed: .x1_0,
            originalRate: 1.0,
            windowDraggable: false
        )
#endif
    }
}
