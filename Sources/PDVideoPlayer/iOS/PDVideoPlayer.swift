#if os(iOS)
import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<MenuContent: View> {
    public let player:  PDVideoPlayerRepresentable
    public let control: VideoPlayerControlView<MenuContent>
    public let navigation: VideoPlayerNavigationView
}
/// A container view that provides video player components.
public struct PDVideoPlayer<MenuContent: View, Content: View>: View {

    @State private var model: PDPlayerModel? = nil

    private var url: URL?
    private var player: AVPlayer?

    private var isMuted: Binding<Bool>?
    private var controlsVisible: Binding<Bool>?
    private var foregroundColor: Color = .white
    private var closeAction: VideoPlayerCloseAction?
    private var longpressAction: VideoPlayerLongpressAction?
    private var panGesture: PDVideoPlayerPanGesture = .rotation

    private let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    private let menuContent: () -> MenuContent

    private var playerID: ObjectIdentifier? { player.map { ObjectIdentifier($0) } }
    
    /// Creates a player from a URL.
    public init(
        url: URL,
        @ViewBuilder menu: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ){
        self.url = url
        self.player = nil
        self.menuContent = menu
        self.content = content
    }
    
    /// Creates a player from an existing AVPlayer instance.
    public init(
        player: AVPlayer,
        @ViewBuilder menu: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ){
        self.player = player
        self.url = nil
        self.menuContent = menu
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            if let model {
                let proxy = PDVideoPlayerProxy(
                    player: PDVideoPlayerRepresentable(
                        model: model,
                        panGesture: panGesture
                    ),
                    control: VideoPlayerControlView(model: model, menuContent: menuContent),
                    navigation: VideoPlayerNavigationView()
                )

                content(proxy)
                    .environment(model)
                    .environment(\.videoPlayerIsMuted, isMuted)
                    .environment(\.videoPlayerControlsVisible, controlsVisible)
                    .environment(\.videoPlayerCloseAction, closeAction)
                    .environment(\.videoPlayerLongpressAction, longpressAction)
                    .environment(\.videoPlayerForegroundColor, foregroundColor)
            }
        }
        .task(id: url) {
            if let url {
                let newModel = PDPlayerModel(url: url)
                newModel.closeAction = closeAction
                model = newModel
            }
        }
        .task(id: playerID) {
            if let player {
                let newModel = PDPlayerModel(player: player)
                newModel.closeAction = closeAction
                model = newModel
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
        self.init(url: url, menu: { EmptyView() }, content: content)
    }

    /// Convenience initializer when no menu content is provided.
    init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(player: player, menu: { EmptyView() }, content: content)
    }
}

#endif
