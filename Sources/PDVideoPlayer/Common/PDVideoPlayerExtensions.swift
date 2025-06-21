#if os(iOS) || os(macOS)
import SwiftUI

public extension PDVideoPlayer {
    func isMuted(_ binding: Binding<Bool>) -> Self {
        var copy = self
        copy.isMuted = binding
        return copy
    }

    func playbackSpeed(_ binding: Binding<PlaybackSpeed>) -> Self {
        var copy = self
        copy.playbackSpeed = binding
        return copy
    }
    
    func onClose(_ action: VideoPlayerCloseAction) -> Self {
        var copy = self
        copy.onClose = action
        return copy
    }

    func onClose(_ action: @escaping (CGFloat) -> Void) -> Self {
        var copy = self
        copy.onClose = VideoPlayerCloseAction(action)
        return copy
    }

    func onLongPress(_ action: VideoPlayerLongpressAction) -> Self {
        var copy = self
        copy.onLongPress = action
        return copy
    }

    func onLongPress(_ action: @escaping (Bool) -> Void) -> Self {
        var copy = self
        copy.onLongPress = VideoPlayerLongpressAction(action)
        return copy
    }

    func playerForegroundColor(_ color: Color) -> Self {
        var copy = self
        copy.foregroundColor = color
        return copy
    }

    /// ````
    /// PDVideoPlayer(url: …) { proxy in … }
    ///     .videoPlayerMenu { Button("…") { … } }
    /// ````
    func videoPlayerMenu<NewMenu: View>(
        @ViewBuilder _ builder: @escaping () -> NewMenu
    ) -> PDVideoPlayer<NewMenu, Content> {

        // 既存 content クロージャを新しいメニュー型にラップ
        let forwardedContent: (PDVideoPlayerProxy<NewMenu>) -> Content = { proxy in
            let oldProxy = PDVideoPlayerProxy<MenuContent>(
                player: proxy.player,
                control: VideoPlayerControlView<MenuContent>(
                    model: proxy.control.model,
                    menuContent: self.menuContent
                ),
                navigation: proxy.navigation
            )
            return self.content(oldProxy)
        }

        return PDVideoPlayer<NewMenu, Content>(
            url:             self.url,
            player:          self.player,
            isMuted:         self.isMuted,
            playbackSpeed:   self.playbackSpeed,
            foregroundColor: self.foregroundColor,
            onClose:         self.onClose,
            onLongPress:     self.onLongPress,
#if os(macOS)
            windowDraggable: self.windowDraggable,
#endif
            menu:            builder,
            content:         forwardedContent
        )
    }

#if os(macOS)
    /// Allows the window to move when dragging on the player view.
    func windowDraggable(_ value: Bool = true) -> Self {
        var copy = self
        copy.windowDraggable = value
        return copy
    }
#endif
}

#endif
