#if os(macOS)
import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<MenuContent: View> {
    public let player: PDVideoPlayerRepresentable<MenuContent>
    public let control: VideoPlayerControlView<MenuContent>
    public let navigation: VideoPlayerNavigationView
}

public struct PDVideoPlayer<MenuContent: View = EmptyView,
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
    
    private var menuContent: () -> MenuContent
    private let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    
    public init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.url = url
        self.menuContent = { EmptyView() }
        self.content = content
    }

    public init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.player = player
        self.menuContent = { EmptyView() }
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
        menuContent: @escaping () -> MenuContent,
        content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
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
        self.menuContent = menuContent
        self.content = content
    }
    
    public var body: some View {
        if let model {
            let proxy = PDVideoPlayerProxy(
                player: PDVideoPlayerRepresentable(
                    model: model,
                    playerViewConfigurator: { _ in },
                    menuContent: menuContent
                ),
                control: VideoPlayerControlView(
                    model: model,
                    menuContent: menuContent
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
    func menuContent<NewMenu: View>(@ViewBuilder _ content: @escaping () -> NewMenu) -> PDVideoPlayer<NewMenu, Content> {
        PDVideoPlayer<NewMenu, Content>(
            model: model,
            url: url,
            player: player,
            isMuted: isMuted,
            playbackSpeed: playbackSpeed,
            onClose: onClose,
            onLongPress: onLongPress,
            foregroundColor: foregroundColor,
            windowDraggable: windowDraggable,
            menuContent: content,
            content: self.content
        )
    }
}

public extension PDVideoPlayer where MenuContent == EmptyView {
    init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(url: url, content: content)
    }

    init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(player: player, content: content)
    }
}

#endif
