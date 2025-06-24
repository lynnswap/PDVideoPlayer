import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<MenuContent: View> {
#if os(macOS)
    public let player: PDVideoPlayerRepresentable<MenuContent>
#else
    public let player: PDVideoPlayerRepresentable
#endif
    public let control: VideoPlayerControlView<MenuContent>
    public let navigation: VideoPlayerNavigationView
}

public struct PDVideoPlayer<MenuContent: View, Content: View>: View {
    @State private var model: PDPlayerModel? = nil
    
    private var url: URL?
    private var player: AVPlayer?
    
    var isMuted: Binding<Bool>?
    var playbackSpeed: Binding<PlaybackSpeed>?
    var onClose: VideoPlayerCloseAction?
    var onLongPress: VideoPlayerLongpressAction?
    var foregroundColor: Color = .white
#if os(macOS)
    /// Enables moving the window when dragging on the player view.
    var windowDraggable: Bool = false
#endif
    
    private let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    private let menuContent: () -> MenuContent
    
    public init(
        url: URL,
        @ViewBuilder menu: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.url = url
        self.menuContent = menu
        self.content = content
    }
    
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
#if os(macOS)
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
#else
            let proxy = PDVideoPlayerProxy(
                player: PDVideoPlayerRepresentable(
                    model: model,
                    scrollViewConfigurator: { _ in }
                ),
                control: VideoPlayerControlView(
                    model: model,
                    menuContent: menuContent
                ),
                navigation: VideoPlayerNavigationView()
            )
#endif
            content(proxy)
                .videoPlayerKeyboardShortcuts(model)
                .environment(model)
                .environment(\.videoPlayerIsMuted, isMuted)
                .environment(\.videoPlayerPlaybackSpeed, playbackSpeed)
                .environment(\.videoPlayerOnClose, onClose)
                .environment(\.videoPlayerOnLongPress, onLongPress)
                .environment(\.videoPlayerForegroundColor, foregroundColor)
                .onChange(of: isMuted?.wrappedValue) {
                    if let isMuted {
                        model.player.isMuted = isMuted.wrappedValue
                    }
                }
                .onChange(of: playbackSpeed?.wrappedValue) {
                    if let speed = playbackSpeed?.wrappedValue {
                        model.playbackSpeed = speed
                    }
                }
                .onChange(of: url) {
                    if let url { model.replacePlayer(url: url) }
                }
                .onChange(of: player) {
                    if let player { model.replacePlayer(with: player) }
                }
#if os(iOS)
                .onChange(of: model.isLongpress) {
                    onLongPress?(model.isLongpress)
                }
#endif
        } else {
            Color.clear
                .task {
                    if let url {
                        let m = PDPlayerModel(url: url)
                        m.onClose = onClose
#if os(macOS)
                        m.windowDraggable = windowDraggable
#endif
                        if let speed = playbackSpeed?.wrappedValue {
                            m.playbackSpeed = speed
                        }
                        model = m
                    } else if let player {
                        let m = PDPlayerModel(player: player)
                        m.onClose = onClose
#if os(macOS)
                        m.windowDraggable = windowDraggable
#endif
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
    init(
        url: URL,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(url: url, menu: { EmptyView() }, content: content)
    }

    init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(player: player, menu: { EmptyView() }, content: content)
    }
}
