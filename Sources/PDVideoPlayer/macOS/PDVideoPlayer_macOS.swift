#if os(macOS)
import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<PlayerMenu: View, ControlMenu: View> {
    public let player: PDVideoPlayerRepresentable<PlayerMenu>
    public let control: VideoPlayerControlView<ControlMenu>
    public let navigation: VideoPlayerNavigationView
}

public struct PDVideoPlayer<PlayerMenu: View = EmptyView,
                            ControlMenu: View = EmptyView,
                            Content: View>: View {
    @State private var model: PDPlayerModel? = nil
    
    private var url: URL?
    private var player: AVPlayer?
    
    var isMuted: Binding<Bool>?
    var playbackSpeed: Binding<PlaybackSpeed>?
    var onClose: VideoPlayerCloseAction?
    var onLongPress: VideoPlayerLongpressAction?
    var foregroundColor: Color = .white
    /// Enables moving the window when dragging on the player view.
    var windowDraggable: Bool = false
    
    private var playerMenu: () -> PlayerMenu
    private var controlMenu: () -> ControlMenu
    private let content: (PDVideoPlayerProxy<PlayerMenu, ControlMenu>) -> Content
    
    public init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<PlayerMenu, ControlMenu>) -> Content
    ) {
        self.url = url
        self.playerMenu = { EmptyView() }
        self.controlMenu = { EmptyView() }
        self.content = content
    }
    
    public init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<PlayerMenu, ControlMenu>) -> Content
    ) {
        self.player = player
        self.playerMenu = { EmptyView() }
        self.controlMenu = { EmptyView() }
        self.content = content
    }

    fileprivate init(
        model: PDPlayerModel?,
        url: URL?,
        player: AVPlayer?,
        isMuted: Binding<Bool>?,
        playbackSpeed: Binding<PlaybackSpeed>?,
        onClose: VideoPlayerCloseAction?,
        onLongPress: VideoPlayerLongpressAction?,
        foregroundColor: Color,
        windowDraggable: Bool,
        playerMenu: @escaping () -> PlayerMenu,
        controlMenu: @escaping () -> ControlMenu,
        content: @escaping (PDVideoPlayerProxy<PlayerMenu, ControlMenu>) -> Content
    ) {
        self._model = State(initialValue: model)
        self.url = url
        self.player = player
        self.isMuted = isMuted
        self.playbackSpeed = playbackSpeed
        self.onClose = onClose
        self.onLongPress = onLongPress
        self.foregroundColor = foregroundColor
        self.windowDraggable = windowDraggable
        self.playerMenu = playerMenu
        self.controlMenu = controlMenu
        self.content = content
    }
    
    public var body: some View {
        if let model {
            let proxy = PDVideoPlayerProxy(
                player: PDVideoPlayerRepresentable(
                    model: model,
                    playerViewConfigurator: { _ in },
                    menuContent: playerMenu
                ),
                control: VideoPlayerControlView(
                    model: model,
                    menuContent: controlMenu
                ),
                navigation: VideoPlayerNavigationView()
            )
            
            content(proxy)
                .videoPlayerKeyboardShortcuts(model)
                .environment(model)
                .environment(\.videoPlayerIsMuted, isMuted)
                .environment(\.videoPlayerPlaybackSpeed, playbackSpeed)
                .environment(\.videoPlayerOnClose, onClose)
                .environment(\.videoPlayerOnLongPress, onLongPress)
                .environment(\.videoPlayerForegroundColor, foregroundColor)
                .onChange(of: isMuted?.wrappedValue){
                    if let isMuted{
                        model.player.isMuted = isMuted.wrappedValue
                    }
                }
                .onChange(of: playbackSpeed?.wrappedValue){
                    if let speed = playbackSpeed?.wrappedValue {
                        model.playbackSpeed = speed
                    }
                }
                .onChange(of: url) {
                    if let url {
                        model.replacePlayer(url: url)
                    }
                }
                .onChange(of: player) {
                    if let player{
                        model.replacePlayer(with: player)
                    }
                }
        }else{
            Color.clear
                .task{
                    if let url {
                        let m = PDPlayerModel(url: url)
                        m.onClose = onClose
                        m.windowDraggable = windowDraggable
                        if let speed = playbackSpeed?.wrappedValue {
                            m.playbackSpeed = speed
                        }
                        model = m
                    } else if let player {
                        let m = PDPlayerModel(player: player)
                        m.onClose = onClose
                        m.windowDraggable = windowDraggable
                        if let speed = playbackSpeed?.wrappedValue {
                            m.playbackSpeed = speed
                        }
                        model = m
                    }
                }
        }
    }
}

public extension PDVideoPlayer {
    func playerMenu<NewMenu: View>(@ViewBuilder _ content: @escaping () -> NewMenu) -> PDVideoPlayer<NewMenu, ControlMenu, Content> {
        PDVideoPlayer<NewMenu, ControlMenu, Content>(
            model: model,
            url: url,
            player: player,
            isMuted: isMuted,
            playbackSpeed: playbackSpeed,
            onClose: onClose,
            onLongPress: onLongPress,
            foregroundColor: foregroundColor,
            windowDraggable: windowDraggable,
            playerMenu: content,
            controlMenu: controlMenu,
            content: self.content
        )
    }

    func controlMenu<NewMenu: View>(@ViewBuilder _ content: @escaping () -> NewMenu) -> PDVideoPlayer<PlayerMenu, NewMenu, Content> {
        PDVideoPlayer<PlayerMenu, NewMenu, Content>(
            model: model,
            url: url,
            player: player,
            isMuted: isMuted,
            playbackSpeed: playbackSpeed,
            onClose: onClose,
            onLongPress: onLongPress,
            foregroundColor: foregroundColor,
            windowDraggable: windowDraggable,
            playerMenu: playerMenu,
            controlMenu: content,
            content: self.content
        )
    }
}

extension PDVideoPlayer where PlayerMenu == ControlMenu {
    public init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<PlayerMenu, PlayerMenu>) -> Content
    ) {
        self.init(url: url, content: content)
    }

    public init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<PlayerMenu, PlayerMenu>) -> Content
    ) {
        self.init(player: player, content: content)
    }
}

#endif
