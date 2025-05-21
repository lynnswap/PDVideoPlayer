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
    var controlsVisible: Binding<Bool>?
    var foregroundColor: Color = .white
    var closeAction: VideoPlayerCloseAction?
    var longpressAction: VideoPlayerLongpressAction?
    var panGesture: PDVideoPlayerPanGesture = .rotation

    private let content: (PDVideoPlayerProxy<MenuContent>) -> Content
    private let menuContent: () -> MenuContent

    private var playerID: ObjectIdentifier? { player.map { ObjectIdentifier($0) } }
    
    /// Creates a player from a URL.
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
        ZStack {
            if let model {
                let proxy = PDVideoPlayerProxy(
                    player: PDVideoPlayerRepresentable(
                        model: model,
                        panGesture: panGesture
                    ),
                    control: VideoPlayerControlView(model: model, menuContent: menuContent),
                    navigation: VideoPlayerNavigationView()
                )

                content(proxy)
                    .onHover(perform: { isHovering in
                        controlsVisible?.wrappedValue = isHovering
                    })
                    .environment(model)
                    .environment(\.videoPlayerIsMuted, isMuted)
                    .environment(\.videoPlayerControlsVisible, controlsVisible)
                    .environment(\.videoPlayerCloseAction, closeAction)
                    .environment(\.videoPlayerLongpressAction, longpressAction)
                    .environment(\.videoPlayerForegroundColor, foregroundColor)
            }
        }
        .onChange(of:foregroundColor){
            guard let slider = model?.slider else { return }
            
            
            let config = UIImage.SymbolConfiguration(
                pointSize: 6,
                weight: .regular,
                scale: .default
            )
            let leftColor:UIColor = UIColor(foregroundColor.opacity(0.8))
            let rightColor:UIColor = UIColor(foregroundColor.opacity(0.3))

            let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: config)?
                .withTintColor(leftColor, renderingMode: .alwaysOriginal)
            slider.setThumbImage(thumbImage, for: .normal)

            slider.minimumTrackTintColor = leftColor
            slider.maximumTrackTintColor = rightColor
        }
        .task(id: url) {
            if let url {
                let newModel = PDPlayerModel(url: url)
                newModel.closeAction = closeAction
                model = newModel
            }
        }
        .task(id: playerID) {
            if let player {
                let newModel = PDPlayerModel(player: player)
                newModel.closeAction = closeAction
                model = newModel
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
