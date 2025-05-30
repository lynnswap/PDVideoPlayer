#if os(iOS) || os(macOS)
import SwiftUI

/// A menu allowing selection of playback speed.
public struct PlaybackSpeedMenuView: View {
    @Environment(PDPlayerModel.self) private var model
    @Environment(\.videoPlayerPlaybackSpeed) private var speedBinding
    public init() {}

    public var body: some View {
        Picker(selection: speedBinding ?? Bindable(model).playbackSpeed) {
            ForEach(PlaybackSpeed.allCases) { speed in
                Text(speed.displayName).tag(speed)
            }
        } label: {
            Label(String(localized:"Playback Speed"), systemImage: "speedometer")
        }
    }
}
#endif
