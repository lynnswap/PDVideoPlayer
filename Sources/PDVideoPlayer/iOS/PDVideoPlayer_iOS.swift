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

    var url: URL?
    var player: AVPlayer?

    var isMuted: Binding<Bool>?
    var playbackSpeed: Binding<PlaybackSpeed>?
    var foregroundColor: Color = .white
    var onClose: VideoPlayerCloseAction?
    var onLongPress: VideoPlayerLongpressAction?

    let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    var menuContent: () -> MenuContent
    
    /// Creates a player from a URL.
    @available(*, deprecated, message: "Use menu() modifier")
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
    @available(*, deprecated, message: "Use menu() modifier")
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
