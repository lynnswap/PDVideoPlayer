import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<MenuContent: View> {
    public let player:  PDVideoPlayerRepresentable
    public let control: VideoPlayerControlView<MenuContent>
}
/// A container view that provides video player components.
public struct PDVideoPlayer<MenuContent: View, Content: View>: View {

    @State private var model: PDPlayerModel? = nil

    private var url: URL?
    private var player: AVPlayer?

    private var isMuted: Binding<Bool>?
    private var isLongpress: Binding<Bool>?
    private var controlsVisible: Binding<Bool>?
    private var originalRate: Binding<Float>?
    private var closeAction: VideoPlayerCloseAction?

    private let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    private let menuContent: () -> MenuContent

    private var playerID: ObjectIdentifier? { player.map { ObjectIdentifier($0) } }
    
    /// Creates a player from a URL.
    public init(
        url: URL,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ){
        self.url = url
        self.player = nil
        self.menuContent = menuContent
        self.content = content
    }
    
    /// Creates a player from an existing AVPlayer instance.
    public init(
        player: AVPlayer,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ){
        self.player = player
        self.url = nil
        self.menuContent = menuContent
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            if let model {
                let proxy = PDVideoPlayerProxy(
                    player: PDVideoPlayerRepresentable(model: model),
                    control: VideoPlayerControlView(model: model, menuContent: menuContent)
                )

                content(proxy)
                    .environment(model)
                    .environment(\.videoPlayerIsMuted, isMuted)
                    .environment(\.videoPlayerIsLongpress, isLongpress)
                    .environment(\.videoPlayerControlsVisible, controlsVisible)
                    .environment(\.videoPlayerOriginalRate, originalRate)
                    .environment(\.videoPlayerCloseAction, closeAction)
            }
        }
        .task(id: url) {
            if let url {
                model = PDPlayerModel(url: url)
            }
        }
        .task(id: playerID) {
            if let player {
                model = PDPlayerModel(player: player)
            }
        }
    }
}

public extension PDVideoPlayer where MenuContent == EmptyView {
    /// Convenience initializer when no menu content is provided.
    init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(url: url, menuContent: { EmptyView() }, content: content)
    }

    /// Convenience initializer when no menu content is provided.
    init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(player: player, menuContent: { EmptyView() }, content: content)
    }
}

public extension PDVideoPlayer {
    /// Sets a binding for the muted state.
    func isMuted(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.isMuted = binding
        return copy
    }

    /// Sets a binding for the long‑press state.
    func isLongpress(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.isLongpress = binding
        return copy
    }

    /// Sets a binding for control visibility.
    func controlsVisible(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.controlsVisible = binding
        return copy
    }

    /// Sets a binding for the original playback rate.
    func originalRate(_ binding: Binding<Float>) -> Self {
        var copy = self
        copy.originalRate = binding
        return copy
    }

    /// Sets a close action for the player.
    func closeAction(_ action: VideoPlayerCloseAction) -> Self {
        var copy = self
        copy.closeAction = action
        return copy
    }
}

