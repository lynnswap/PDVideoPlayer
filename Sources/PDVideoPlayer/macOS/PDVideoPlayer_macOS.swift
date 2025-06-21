#if os(macOS)
import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<MenuContent: View> {
    public let player: PDVideoPlayerRepresentable<MenuContent>
    public let control: VideoPlayerControlView<MenuContent>
    public let navigation: VideoPlayerNavigationView
}

public struct PDVideoPlayer<MenuContent: View,
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

    let menuContent: () -> MenuContent
    let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    

    // videoPlayerMenu 用のコピー用 internal イニシャライザ
    init(
        url: URL?,
        player: AVPlayer?,
        isMuted: Binding<Bool>?,
        playbackSpeed: Binding<PlaybackSpeed>?,
        foregroundColor: Color,
        onClose: VideoPlayerCloseAction?,
        onLongPress: VideoPlayerLongpressAction?,
        windowDraggable: Bool,
        @ViewBuilder menu: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.url             = url
        self.player          = player
        self.isMuted         = isMuted
        self.playbackSpeed   = playbackSpeed
        self.onClose         = onClose
        self.onLongPress     = onLongPress
        self.foregroundColor = foregroundColor
        self.windowDraggable = windowDraggable

        self.menuContent = menu
        self.content     = content
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

public extension PDVideoPlayer where MenuContent == EmptyView {
    /// メニューなしの場合のコンビニエンス初期化
    init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(
            url:             url,
            player:          nil,
            isMuted:         nil,
            playbackSpeed:   nil,
            foregroundColor: .white,
            onClose:         nil,
            onLongPress:     nil,
            windowDraggable: false,
            menu:            { EmptyView() },
            content:         content
        )
    }

    /// メニューなしの場合のコンビニエンス初期化
    init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(
            url:             nil,
            player:          player,
            isMuted:         nil,
            playbackSpeed:   nil,
            foregroundColor: .white,
            onClose:         nil,
            onLongPress:     nil,
            windowDraggable: false,
            menu:            { EmptyView() },
            content:         content
        )
    }

    /// ``PDVideoPlayer(url:)`` 等に後付けでメニューを設定するモディファイア
    func videoPlayerMenu<NewMenu: View>(
        @ViewBuilder _ builder: @escaping () -> NewMenu
    ) -> PDVideoPlayer<NewMenu, Content> {
        let forwardedContent = unsafeBitCast(
            self.content,
            to: ((PDVideoPlayerProxy<NewMenu>) -> Content).self
        )

        return PDVideoPlayer<NewMenu, Content>(
            url:             self.url,
            player:          self.player,
            isMuted:         self.isMuted,
            playbackSpeed:   self.playbackSpeed,
            foregroundColor: self.foregroundColor,
            onClose:         self.onClose,
            onLongPress:     self.onLongPress,
            windowDraggable: self.windowDraggable,
            menu:            builder,
            content:         forwardedContent
        )
    }
}

#endif
