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

    public func menu<NewMenu: View>(@ViewBuilder _ menu: @escaping () -> NewMenu) -> PDVideoPlayer<NewMenu, NewMenu, Content> {
        PDVideoPlayer<NewMenu, NewMenu, Content>(
            url: self.url,
            player: self.player,
            isMuted: self.isMuted,
            playbackSpeed: self.playbackSpeed,
            foregroundColor: self.foregroundColor,
            onClose: self.onClose,
            onLongPress: self.onLongPress,
            windowDraggable: self.windowDraggable,
            playerMenu: menu,
            controlMenu: menu,
            content: self.content
        )
    }

    public func playerMenu<NewMenu: View>(@ViewBuilder _ menu: @escaping () -> NewMenu) -> PDVideoPlayer<NewMenu, ControlMenu, Content> {
        PDVideoPlayer<NewMenu, ControlMenu, Content>(
            url: self.url,
            player: self.player,
            isMuted: self.isMuted,
            playbackSpeed: self.playbackSpeed,
            foregroundColor: self.foregroundColor,
            onClose: self.onClose,
            onLongPress: self.onLongPress,
            windowDraggable: self.windowDraggable,
            playerMenu: menu,
            controlMenu: self.controlMenu,
            content: self.content
        )
    }

    public func controlMenu<NewMenu: View>(@ViewBuilder _ menu: @escaping () -> NewMenu) -> PDVideoPlayer<PlayerMenu, NewMenu, Content> {
        PDVideoPlayer<PlayerMenu, NewMenu, Content>(
            url: self.url,
            player: self.player,
            isMuted: self.isMuted,
            playbackSpeed: self.playbackSpeed,
            foregroundColor: self.foregroundColor,
            onClose: self.onClose,
            onLongPress: self.onLongPress,
            windowDraggable: self.windowDraggable,
            playerMenu: self.playerMenu,
            controlMenu: menu,
            content: self.content
        )
    }

    init(
        url: URL?,
        player: AVPlayer?,
        isMuted: Binding<Bool>?,
        playbackSpeed: Binding<PlaybackSpeed>?,
        foregroundColor: Color,
        onClose: VideoPlayerCloseAction?,
        onLongPress: VideoPlayerLongpressAction?,
        windowDraggable: Bool,
        @ViewBuilder playerMenu: @escaping () -> PlayerMenu,
        @ViewBuilder controlMenu: @escaping () -> ControlMenu,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<PlayerMenu, ControlMenu>) -> Content
    ) {
        self.url = url
        self.player = player
        self.isMuted = isMuted
        self.playbackSpeed = playbackSpeed
        self.foregroundColor = foregroundColor
        self.onClose = onClose
        self.onLongPress = onLongPress
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



#endif
