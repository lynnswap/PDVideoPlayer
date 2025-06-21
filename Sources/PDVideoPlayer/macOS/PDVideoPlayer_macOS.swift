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
    
    var url: URL?
    var player: AVPlayer?
    
    var isMuted: Binding<Bool>?
    var playbackSpeed: Binding<PlaybackSpeed>?
    var onClose: VideoPlayerCloseAction?
    var onLongPress: VideoPlayerLongpressAction?
    var foregroundColor: Color = .white
    /// Enables moving the window when dragging on the player view.
    var windowDraggable: Bool = false
    
    var menuContent: () -> MenuContent
    let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    
    @available(*, deprecated, message: "Use menu() modifier")
    public init(
        url: URL,
        @ViewBuilder menu: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.url = url
        self.menuContent = menu
        self.content = content
    }

    @available(*, deprecated, message: "Use menu() modifier")
    public init(
        player: AVPlayer,
        @ViewBuilder menu: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.player = player
        self.menuContent = menu
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



#endif
