#if os(macOS)
import SwiftUI
import AVKit

public struct PDVideoPlayerProxy<PlayerMenu: View, ControlMenu: View> {
    public let player: PDVideoPlayerRepresentable<PlayerMenu>
    public let control: VideoPlayerControlView<ControlMenu>
    public let navigation: VideoPlayerNavigationView
}

public struct PDVideoPlayer<PlayerMenu: View,
                            ControlMenu: View,
                            Content: View>: View {
    @State private var model: PDPlayerModel? = nil
    
    private var url: URL?
    private var player: AVPlayer?
    
    var isMuted: Binding<Bool>?
    var closeAction: VideoPlayerCloseAction?
    var longpressAction: VideoPlayerLongpressAction?
    var foregroundColor: Color = .white
    /// Enables moving the window when dragging on the player view.
    var windowDraggable: Bool = false
    
    private let playerMenu: () -> PlayerMenu
    private let controlMenu: () -> ControlMenu
    private let content: (PDVideoPlayerProxy<PlayerMenu, ControlMenu>) -> Content
    
    
    private var playerID: ObjectIdentifier? { player.map { ObjectIdentifier($0) } }
    
    public init(
        url: URL,
        @ViewBuilder playerMenu: @escaping () -> PlayerMenu,
        @ViewBuilder controlMenu: @escaping () -> ControlMenu,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<PlayerMenu, ControlMenu>) -> Content
    ) {
        self.url = url
        self.playerMenu = playerMenu
        self.controlMenu = controlMenu
        self.content = content
    }
    
    public init(
        player: AVPlayer,
        @ViewBuilder playerMenu: @escaping () -> PlayerMenu,
        @ViewBuilder controlMenu: @escaping () -> ControlMenu,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<PlayerMenu, ControlMenu>) -> Content
    ) {
        self.player = player
        self.playerMenu = playerMenu
        self.controlMenu = controlMenu
        self.content = content
    }
    
    public var body: some View {
        ZStack {
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
                    .environment(model)
                    .environment(\.videoPlayerIsMuted, isMuted)
                    .environment(\.videoPlayerCloseAction, closeAction)
                    .environment(\.videoPlayerLongpressAction, longpressAction)
                    .environment(\.videoPlayerForegroundColor, foregroundColor)
            }
        }
        .onChange(of:foregroundColor){
            model?.slider.baseColor = NSColor(foregroundColor)
        }
        .task(id: url) {
            if let url {
                let m = PDPlayerModel(url: url)
                m.closeAction = closeAction
                m.windowDraggable = windowDraggable
                model = m
            }
        }
        .task(id: playerID) {
            if let player {
                let m = PDPlayerModel(player: player)
                m.closeAction = closeAction
                m.windowDraggable = windowDraggable
                model = m
            }
        }
    }
}

extension PDVideoPlayer where PlayerMenu == ControlMenu {
    public init(
        url: URL,
        @ViewBuilder menu: @escaping () -> PlayerMenu,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<PlayerMenu, PlayerMenu>) -> Content
    ) {
        self.init(
            url: url,
            playerMenu: menu,
            controlMenu: menu,
            content: content
        )
    }
    
    public init(
        player: AVPlayer,
        @ViewBuilder menu: @escaping () -> PlayerMenu,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<PlayerMenu, PlayerMenu>) -> Content
    ) {
        self.init(
            player: player,
            playerMenu: menu,
            controlMenu: menu,
            content: content
        )
    }
}

#endif
