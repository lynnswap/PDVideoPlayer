import SwiftUI
import AVKit

/// A container view that provides video player components.
public struct PDVideoPlayerView<MenuContent: View, Content: View>: View {

    @State private var model: PDPlayerModel

    private var isMuted: Binding<Bool>?
    private var isLongpress: Binding<Bool>?
    private var controlsVisible: Binding<Bool>?
    private var originalRate: Binding<Float>?
    private var closeAction: VideoPlayerCloseAction?

    private let menuContent: () -> MenuContent
    private let content: (Proxy) -> Content

    /// Proxy that exposes player and control views.
    public struct Proxy {
        public let player: PDVideoPlayerRepresentable
        public let control: VideoPlayerControlView<MenuContent>
    }

    init(model: PDPlayerModel,
         isMuted: Binding<Bool>? = nil,
         isLongpress: Binding<Bool>? = nil,
         controlsVisible: Binding<Bool>? = nil,
         originalRate: Binding<Float>? = nil,
         closeAction: VideoPlayerCloseAction? = nil,
         @ViewBuilder menuContent: @escaping () -> MenuContent,
         @ViewBuilder content: @escaping (Proxy) -> Content) {
        self._model = State(initialValue: model)
        self.isMuted = isMuted
        self.isLongpress = isLongpress
        self.controlsVisible = controlsVisible
        self.originalRate = originalRate
        self.closeAction = closeAction
        self.menuContent = menuContent
        self.content = content
    }

    /// Creates a player from a URL.
    public init(url: URL,
                @ViewBuilder menuContent: @escaping () -> MenuContent,
                @ViewBuilder content: @escaping (Proxy) -> Content) {
        self.init(model: PDPlayerModel(url: url),
                  menuContent: menuContent,
                  content: content)
    }

    /// Creates a player from an existing AVPlayer instance.
    public init(player: AVPlayer,
                @ViewBuilder menuContent: @escaping () -> MenuContent,
                @ViewBuilder content: @escaping (Proxy) -> Content) {
        self.init(model: PDPlayerModel(player: player),
                  menuContent: menuContent,
                  content: content)
    }

    public var body: some View {
        let proxy = Proxy(
            player: PDVideoPlayerRepresentable(model: model)
                .rippleEffect(model) { store in
                    model.rippleStore = store
                },
            control: VideoPlayerControlView(model: model, menuContent: menuContent)
        )

        return content(proxy)
            .environment(\.videoPlayerIsMuted, isMuted)
            .environment(\.videoPlayerIsLongpress, isLongpress)
            .environment(\.videoPlayerControlsVisible, controlsVisible)
            .environment(\.videoPlayerOriginalRate, originalRate)
            .environment(\.videoPlayerCloseAction, closeAction)
    }
}

public extension PDVideoPlayerView where MenuContent == EmptyView {
    /// Convenience initializer when no menu content is provided.
    public init(url: URL,
                @ViewBuilder content: @escaping (Proxy) -> Content) {
        self.init(url: url, menuContent: { EmptyView() }, content: content)
    }

    /// Convenience initializer when no menu content is provided.
    public init(player: AVPlayer,
                @ViewBuilder content: @escaping (Proxy) -> Content) {
        self.init(player: player, menuContent: { EmptyView() }, content: content)
    }
}

public extension PDVideoPlayerView {
    /// Sets a binding for the muted state.
    func isMuted(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.isMuted = binding
        return copy
    }

    /// Sets a binding for the long‑press state.
    func isLongpress(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.isLongpress = binding
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
}

