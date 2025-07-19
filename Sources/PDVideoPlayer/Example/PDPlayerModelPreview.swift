#if DEBUG
import SwiftUI
import AVKit

/// A helper view for SwiftUI previews that provides a `PDPlayerModel` environment.
public struct PDPlayerModelPreview<Content: View>: View {
    @State private var model: PDPlayerModel
    private let content: (PDPlayerModel) -> Content

    public init(player: AVPlayer = AVPlayer(),
                @ViewBuilder content: @escaping (PDPlayerModel) -> Content) {
        _model = State(initialValue: PDPlayerModel(player: player))
        self.content = content
    }

    public var body: some View {
        content(model)
            .environment(model)
    }
}
#endif
