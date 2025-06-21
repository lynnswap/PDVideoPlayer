#if os(iOS)
import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<MenuContent: View> {
    public let player: PDVideoPlayerRepresentable
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
    private var menuContent: () -> MenuContent
    
    /// Creates a player from a URL.
    public init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ){
        self.url = url
        self.player = nil
        self.menuContent = { EmptyView() }
        self.content = content
    }
    
    /// Creates a player from an existing AVPlayer instance.
    public init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ){
        self.player = player
        self.url = nil
        self.menuContent = { EmptyView() }
        self.content = content
    }

    fileprivate init(
        model: PDPlayerModel?,
        url: URL?,
        player: AVPlayer?,
        isMuted: Binding<Bool>?,
        playbackSpeed: Binding<PlaybackSpeed>?,
        foregroundColor: Color,
        onClose: VideoPlayerCloseAction?,
        onLongPress: VideoPlayerLongpressAction?,
        menuContent: @escaping () -> MenuContent,
        content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self._model = State(initialValue: model)
        self.url = url
        self.player = player
        self.isMuted = isMuted
        self.playbackSpeed = playbackSpeed
        self.foregroundColor = foregroundColor
        self.onClose = onClose
        self.onLongPress = onLongPress
        self.menuContent = menuContent
        self.content = content
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

public extension PDVideoPlayer {
    func menuContent<NewMenu: View>(@ViewBuilder _ content: @escaping () -> NewMenu) -> PDVideoPlayer<NewMenu, Content> {
        PDVideoPlayer<NewMenu, Content>(
            model: model,
            url: url,
            player: player,
            isMuted: isMuted,
            playbackSpeed: playbackSpeed,
            foregroundColor: foregroundColor,
            onClose: onClose,
            onLongPress: onLongPress,
            menuContent: content,
            content: self.content
        )
    }
}

public extension PDVideoPlayer where MenuContent == EmptyView {
    /// Convenience initializer when no menu content is provided.
    init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(url: url, content: content)
    }

    /// Convenience initializer when no menu content is provided.
    init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(player: player, content: content)
    }
}

#endif
