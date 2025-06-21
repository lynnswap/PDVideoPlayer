#if os(iOS)
import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<MenuContent: View> {
    public let player:     PDVideoPlayerRepresentable
    public let control:    VideoPlayerControlView<MenuContent>
    public let navigation: VideoPlayerNavigationView
}
/// A container view that provides video player components.
public struct PDVideoPlayer<MenuContent: View, Content: View>: View {

    // ① モデル (Runtime‑only)
    @State private var model: PDPlayerModel? = nil

    // ② 設定パラメータ (コピーして保持)
    //    ⇒ `internal` にして videoPlayerMenu から読めるように
    var url: URL?
    var player: AVPlayer?

    var isMuted: Binding<Bool>?
    var playbackSpeed: Binding<PlaybackSpeed>?
    var foregroundColor: Color
    var onClose: VideoPlayerCloseAction?
    var onLongPress: VideoPlayerLongpressAction?

    // ③ 描画クロージャ
    let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    let menuContent: () -> MenuContent


    // ================================================================== //
    // MARK: パブリック designated 初期化
    // ================================================================== //


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
        @ViewBuilder menu: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.url             = url
        self.player          = player
        self.isMuted         = isMuted
        self.playbackSpeed   = playbackSpeed
        self.foregroundColor = foregroundColor
        self.onClose         = onClose
        self.onLongPress     = onLongPress

        self.menuContent = menu
        self.content     = content
    }
    
    public var body: some View {
        if let model {
            let proxy = PDVideoPlayerProxy(
                player: PDVideoPlayerRepresentable(
                    model: model
                ),
                control: VideoPlayerControlView(model: model, menuContent: menuContent),
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
                        let newModel = PDPlayerModel(url: url)
                        newModel.onClose = onClose
                        if let speed = playbackSpeed?.wrappedValue {
                            newModel.playbackSpeed = speed
                        }
                        model = newModel
                    } else if let player {
                        let newModel = PDPlayerModel(player: player)
                        newModel.onClose = onClose
                        if let speed = playbackSpeed?.wrappedValue {
                            newModel.playbackSpeed = speed
                        }
                        model = newModel
                    }
                }
        }
    }
}

public extension PDVideoPlayer where MenuContent == EmptyView {
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
            menu:            { EmptyView() },
            content:         content
        )
    }

    // .videoPlayerMenu は共通拡張へ移動
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
            menu:            builder,
            content:         forwardedContent
        )
    }
}

#endif
