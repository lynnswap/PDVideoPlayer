#if os(macOS)
import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<MenuContent: View> {
    public let player: PDVideoPlayerRepresentable<MenuContent>
    public let control: VideoPlayerControlView<MenuContent>
    public let navigation: VideoPlayerNavigationView
}

public extension PDVideoPlayer where MenuContent == EmptyView {
    public init(
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

    public init(
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

    // .videoPlayerMenu は共通拡張へ移動
}

public struct PDVideoPlayer<MenuContent: View, Content: View>: View {
    // ------------------------------------------------------------------ //
    // ① モデル (Runtime‑only)
    // ------------------------------------------------------------------ //
    @State private var model: PDPlayerModel? = nil

    // ------------------------------------------------------------------ //
    // ② 設定パラメータ (コピーして保持)
    //    ⇒ `internal` にして videoPlayerMenu から読めるように
    // ------------------------------------------------------------------ //
    var url: URL?
    var player: AVPlayer?

    var isMuted: Binding<Bool>?
    var playbackSpeed: Binding<PlaybackSpeed>?
    var onClose: VideoPlayerCloseAction?
    var onLongPress: VideoPlayerLongpressAction?
    var foregroundColor: Color
    /// Enables moving the window when dragging on the player view.
    var windowDraggable: Bool

    // ------------------------------------------------------------------ //
    // ③ 描画クロージャ
    // ------------------------------------------------------------------ //
    let menuContent: () -> MenuContent
    let content: (PDVideoPlayerProxy<MenuContent>) -> Content

    // ------------------------------------------------------------------ //
    // ④ videoPlayerMenu 用のコピー用 internal イニシャライザ
    // ------------------------------------------------------------------ //
    internal init(
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



#endif
