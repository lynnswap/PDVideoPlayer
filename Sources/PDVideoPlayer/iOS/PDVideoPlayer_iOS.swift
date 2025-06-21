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

    var isMuted: Binding<Bool>?
    var playbackSpeed: Binding<PlaybackSpeed>?
    var foregroundColor: Color = .white
    var onClose: VideoPlayerCloseAction?
    var onLongPress: VideoPlayerLongpressAction?

    private let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    private let menuContent: () -> MenuContent
    
    init(
        url: URL?,
        player: AVPlayer?,
        isMuted: Binding<Bool>? = nil,
        playbackSpeed: Binding<PlaybackSpeed>? = nil,
        foregroundColor: Color = .white,
        onClose: VideoPlayerCloseAction? = nil,
        onLongPress: VideoPlayerLongpressAction? = nil,
        @ViewBuilder menu: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.url = url
        self.player = player
        self.isMuted = isMuted
        self.playbackSpeed = playbackSpeed
        self.foregroundColor = foregroundColor
        self.onClose = onClose
        self.onLongPress = onLongPress
        self.menuContent = menu
        self.content = content
    }

    /// Creates a player from a URL.
    public init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) where MenuContent == EmptyView {
        self.init(url: url,
                  player: nil,
                  menu: { EmptyView() },
                  content: content)
    }

    /// Creates a player from an existing AVPlayer instance.
    public init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) where MenuContent == EmptyView {
        self.init(url: nil,
                  player: player,
                  menu: { EmptyView() },
                  content: content)
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
    /// Convenience initializer when no menu content is provided.
    init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(url: url, player: nil, menu: { EmptyView() }, content: content)
    }

    /// Convenience initializer when no menu content is provided.
    init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(url: nil, player: player, menu: { EmptyView() }, content: content)
    }

    /// Sets the menu content for this player.
    func menu<Menu: View>(@ViewBuilder _ menu: @escaping () -> Menu) -> PDVideoPlayer<Menu, Content> {
        PDVideoPlayer<Menu, Content>(
            url: self.url,
            player: self.player,
            isMuted: self.isMuted,
            playbackSpeed: self.playbackSpeed,
            foregroundColor: self.foregroundColor,
            onClose: self.onClose,
            onLongPress: self.onLongPress,
            menu: menu,
            content: unsafeBitCast(self.content, to: ((PDVideoPlayerProxy<Menu>) -> Content).self)
        )
    }
}

#endif
