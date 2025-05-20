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

    private var isMuted: Binding<Bool>?
    private var controlsVisible: Binding<Bool>?
    private var originalRate: Binding<Float>?
    private var closeAction: VideoPlayerCloseAction?
    private var longpressAction: VideoPlayerLongpressAction?
#if os(iOS)
    private var scrollViewConfigurator: PDVideoPlayerRepresentable.ScrollViewConfigurator?
    private var contextMenuProvider: PDVideoPlayerRepresentable.ContextMenuProvider?
#endif

    private let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    private let menuContent: () -> MenuContent

    private var playerID: ObjectIdentifier? { player.map { ObjectIdentifier($0) } }
    
    /// Creates a player from a URL.
    public init(
        url: URL,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ){
        self.url = url
        self.player = nil
        self.menuContent = menuContent
        self.content = content
    }
    
    /// Creates a player from an existing AVPlayer instance.
    public init(
        player: AVPlayer,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ){
        self.player = player
        self.url = nil
        self.menuContent = menuContent
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            if let model {
                let proxy: PDVideoPlayerProxy<MenuContent>
#if os(iOS)
                proxy = PDVideoPlayerProxy(
                    player: PDVideoPlayerRepresentable(
                        model: model,
                        scrollViewConfigurator: scrollViewConfigurator,
                        contextMenuProvider: contextMenuProvider
                    ),
                    control: VideoPlayerControlView(model: model, menuContent: menuContent),
                    navigation: VideoPlayerNavigationView()
                )
#else
                proxy = PDVideoPlayerProxy(
                    player: PDVideoPlayerRepresentable(model: model),
                    control: VideoPlayerControlView(model: model, menuContent: menuContent),
                    navigation: VideoPlayerNavigationView()
                )
#endif

                content(proxy)
                    .environment(model)
                    .environment(\.videoPlayerIsMuted, isMuted)
                    .environment(\.videoPlayerControlsVisible, controlsVisible)
                    .environment(\.videoPlayerOriginalRate, originalRate)
                    .environment(\.videoPlayerCloseAction, closeAction)
                    .environment(\.videoPlayerLongpressAction, longpressAction)
            }
        }
        .task(id: url) {
            if let url {
                model = PDPlayerModel(url: url)
            }
        }
        .task(id: playerID) {
            if let player {
                model = PDPlayerModel(player: player)
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
        self.init(url: url, menuContent: { EmptyView() }, content: content)
    }

    /// Convenience initializer when no menu content is provided.
    init(
        player: AVPlayer,
        @ViewBuilder content: @escaping (PDVideoPlayerProxy<MenuContent>) -> Content
    ) {
        self.init(player: player, menuContent: { EmptyView() }, content: content)
    }
}

public extension PDVideoPlayer {
    /// Sets a binding for the muted state.
    func isMuted(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.isMuted = binding
        return copy
    }

    /// Sets a binding for control visibility.
    func controlsVisible(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.controlsVisible = binding
        return copy
    }

    /// Sets a binding for the original playback rate.
    func originalRate(_ binding: Binding<Float>) -> Self {
        var copy = self
        copy.originalRate = binding
        return copy
    }

    /// Sets a close action for the player.
    func closeAction(_ action: VideoPlayerCloseAction) -> Self {
        var copy = self
        copy.closeAction = action
        return copy
    }

    /// Convenience overload to set a close action using a simple closure.
    func closeAction(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.closeAction = VideoPlayerCloseAction(action)
        return copy
    }

    /// Sets an action triggered when long‑press state changes.
    func longpressAction(_ action: VideoPlayerLongpressAction) -> Self {
        var copy = self
        copy.longpressAction = action
        return copy
    }

    /// Convenience overload to set a long‑press action using a simple closure.
    func longpressAction(_ action: @escaping (Bool) -> Void) -> Self {
        var copy = self
        copy.longpressAction = VideoPlayerLongpressAction(action)
        return copy
    }

#if os(iOS)
    /// Configures the internal `UIScrollView`.
    func scrollViewConfigurator(_ configurator: @escaping PDVideoPlayerRepresentable.ScrollViewConfigurator) -> Self {
        var copy = self
        copy.scrollViewConfigurator = configurator
        return copy
    }

    /// Provides a context menu for long‑press interactions.
    func contextMenuProvider(_ provider: @escaping PDVideoPlayerRepresentable.ContextMenuProvider) -> Self {
        var copy = self
        copy.contextMenuProvider = provider
        return copy
    }
#endif
}

