#if os(macOS)
import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<MenuContent: View> {
    public let player: PDVideoPlayerRepresentable<MenuContent>
    public let control: VideoPlayerControlView<MenuContent>
    public let navigation: VideoPlayerNavigationView
}

public struct PDVideoPlayer<MenuContent: View, Content: View>: View {
    @State private var model: PDPlayerModel? = nil

    private var url: URL?
    private var player: AVPlayer?

    private var isMuted: Binding<Bool>?
    private var controlsVisible: Binding<Bool>?
    private var originalRate: Binding<Float>?
    private var closeAction: VideoPlayerCloseAction?
    private var longpressAction: VideoPlayerLongpressAction?

    private let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    private let menuContent: () -> MenuContent

    private var playerID: ObjectIdentifier? { player.map { ObjectIdentifier($0) } }

    public init(
        url: URL,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.url = url
        self.menuContent = menuContent
        self.content = content
    }

    public init(
        player: AVPlayer,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.player = player
        self.menuContent = menuContent
        self.content = content
    }

    public var body: some View {
        ZStack {
            if let model {
                let proxy = PDVideoPlayerProxy(
                    player: PDVideoPlayerRepresentable(
                        player: model.player,
                        playerViewConfigurator: { $0.controlsStyle = .none },
                        menuContent: menuContent
                    ),
                    control: VideoPlayerControlView(model: model, menuContent: menuContent),
                    navigation: VideoPlayerNavigationView()
                )

                content(proxy)
                    .environment(model)
                    .environment(\.videoPlayerIsMuted, isMuted)
                    .environment(\.videoPlayerControlsVisible, controlsVisible)
                    .environment(\.videoPlayerOriginalRate, originalRate)
                    .environment(\.videoPlayerCloseAction, closeAction)
                    .environment(\.videoPlayerLongpressAction, longpressAction)
            }
        }
        .task(id: url) {
            if let url {
                let m = PDPlayerModel(url: url)
                m.closeAction = closeAction
                model = m
            }
        }
        .task(id: playerID) {
            if let player {
                let m = PDPlayerModel(player: player)
                m.closeAction = closeAction
                model = m
            }
        }
    }
}

public extension PDVideoPlayer where MenuContent == EmptyView {
    init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(url: url, menuContent: { EmptyView() }, content: content)
    }

    init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(player: player, menuContent: { EmptyView() }, content: content)
    }
}

public extension PDVideoPlayer {
    func isMuted(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.isMuted = binding
        return copy
    }

    func controlsVisible(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.controlsVisible = binding
        return copy
    }

    func originalRate(_ binding: Binding<Float>) -> Self {
        var copy = self
        copy.originalRate = binding
        return copy
    }

    func closeAction(_ action: VideoPlayerCloseAction) -> Self {
        var copy = self
        copy.closeAction = action
        return copy
    }

    func closeAction(_ action: @escaping (CGFloat) -> Void) -> Self {
        var copy = self
        copy.closeAction = VideoPlayerCloseAction(action)
        return copy
    }

    func longpressAction(_ action: VideoPlayerLongpressAction) -> Self {
        var copy = self
        copy.longpressAction = action
        return copy
    }

    func longpressAction(_ action: @escaping (Bool) -> Void) -> Self {
        var copy = self
        copy.longpressAction = VideoPlayerLongpressAction(action)
        return copy
    }

    func panGesture(_ gesture: PDVideoPlayerPanGesture) -> Self {
        self
    }
}
#endif
