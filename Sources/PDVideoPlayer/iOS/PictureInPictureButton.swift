#if canImport(UIKit) && !os(visionOS)
import SwiftUI

/// Button to start Picture-in-Picture playback.
public struct PictureInPictureButton: View {
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor

    public init() {}

    public var body: some View {
        Button {
            PiPManager.shared.start()
        } label: {
            ZStack {
                Color.clear
                Image(systemName: "pip.enter")
                    .foregroundStyle(foregroundColor)
                    .fontDesign(.rounded)
                    .opacity(0.8)
            }
            .contentShape(Rectangle())
        }
    }
}
#endif
