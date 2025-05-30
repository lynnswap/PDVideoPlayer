//
//  VideoPlayerViewControllerRepresentable.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/13.
//

#if os(macOS)
import SwiftUI
import AVKit

public typealias PDVideoPlayerRepresentable = PDVideoPlayerView_macOS

public struct PDVideoPlayerView_macOS<MenuContent: View>: NSViewRepresentable {
    public typealias ContextMenuProvider = (CGPoint) -> NSMenu?
    public typealias PlayerViewConfigurator = (PlayerNSView) -> Void
    public typealias ScrollViewConfigurator = (NSScrollView) -> Void
    public typealias PresentationSizeAction = ((_ view: NSView, _ size: CGSize) -> Void)

    var model: PDPlayerModel
    let menuContent: () -> MenuContent
    let onPresentationSizeChange: PresentationSizeAction?
    let scrollViewConfigurator: ScrollViewConfigurator?
    let playerViewConfigurator: PlayerViewConfigurator?
    let onTap: VideoPlayerTapAction?
    
    public init(
        model: PDPlayerModel,
        scrollViewConfigurator: ScrollViewConfigurator? = nil,
        playerViewConfigurator: PlayerViewConfigurator? = nil,
        onPresentationSizeChange: PresentationSizeAction? = nil,
        onTap: VideoPlayerTapAction? = nil,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.model = model
        self.scrollViewConfigurator = scrollViewConfigurator
        self.playerViewConfigurator = playerViewConfigurator
        self.menuContent = menuContent
        self.onPresentationSizeChange = onPresentationSizeChange
        self.onTap = onTap

    }
    
    @Environment(\.videoPlayerOnLongPress) private var onLongPress
    
    @MainActor
    final public class Coordinator: NSObject {
        var presentationSizeObservation: NSKeyValueObservation?
        var parent: PDVideoPlayerView_macOS
        weak var playerView: PlayerNSView?

        init(_ parent: PDVideoPlayerView_macOS) {
            self.parent = parent
        }

        @objc func handleClick(_ recognizer: NSClickGestureRecognizer) {
            guard let playerView else {
                parent.onTap?(true)
                return
            }

            let locationInPlayerView = recognizer.location(in: playerView)
            let videoRect = playerView.videoBounds
            let inside = videoRect.contains(locationInPlayerView)
            parent.onTap?(inside)
        }
    }
    public static func dismantleNSView(
        _ nsView: NSScrollView,
        coordinator: Coordinator
    ){
        coordinator.presentationSizeObservation?.invalidate()
        coordinator.presentationSizeObservation = nil
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let playerView = model.setupPlayerView()
        context.coordinator.playerView = playerView

        let scrollView = model.scrollView

        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor
        scrollView.documentView = containerView

        containerView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            playerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            playerView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            playerView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])
        scrollView.usesPredominantAxisScrolling = false
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 1.0
        scrollView.maxMagnification = 4.0
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        
        let singleClickGestureRecognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        singleClickGestureRecognizer.numberOfClicksRequired = 1
        containerView.addGestureRecognizer(singleClickGestureRecognizer)

        scrollViewConfigurator?(scrollView)


        if #available(macOS 14.4, *) {
            let hostingMenu = NSHostingMenu(rootView: menuContent())
            playerView.menu = hostingMenu
        }
        playerViewConfigurator?(playerView)


        model.player.appliesMediaSelectionCriteriaAutomatically = false

        if let playerItem = model.player.currentItem {
            context.coordinator.presentationSizeObservation?.invalidate()
            context.coordinator.presentationSizeObservation = nil
            context.coordinator.presentationSizeObservation = playerItem.observe(\.presentationSize, options: [.new, .initial]) { item, change in
                let size = item.presentationSize
                if size.width > 0, size.height > 0 {
                    Task{ @MainActor in
                        context.coordinator.presentationSizeObservation?.invalidate()
                        context.coordinator.presentationSizeObservation = nil
                        playerView.setConstraintScalledToFit(in:containerView,size:size)
                        onPresentationSizeChange?(playerView,size)
                    }
                }
            }
        }
        
        return scrollView
    }

    public func updateNSView(_ uiView: NSScrollView, context: Context) {
    }
}


public class PlayerNSView: NSView {
    weak var model: PDPlayerModel?

    /// When true, dragging on this view moves the containing window.
    var isWindowDraggable: Bool = false

    private var zoomScale: CGFloat = 1.0
    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 4.0

    private func updateTransform() {
        self.layer?.setAffineTransform(CGAffineTransform(scaleX: zoomScale, y: zoomScale))
    }

    // MARK: - Lifecycle

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // レイヤーを持つようにする
        self.wantsLayer = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Nib/Storyboard経由の場合もレイヤーを持つようにする
        self.wantsLayer = true
    }

    // This view needs to receive key events for playback shortcuts
    public override var acceptsFirstResponder: Bool { true }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    public override func mouseDown(with event: NSEvent) {
        if isWindowDraggable {
            window?.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }

    public override func magnify(with event: NSEvent) {
        super.magnify(with: event)
    }

    // UIView の layerClass 相当
    public override func makeBackingLayer() -> CALayer {
        // ここで AVPlayerLayer を返すことで、
        // self.layer が必ず AVPlayerLayer になる
        return AVPlayerLayer()
    }

    // MARK: - Player

    func setPlayer(_ player: AVPlayer, videoGravity: AVLayerVideoGravity) {
        // wantsLayer が有効になった後なら、layer は AVPlayerLayer に置き換わっているはず
        guard let playerLayer = self.layer as? AVPlayerLayer else {
            // デバッグ用にエラー出力するなり、ここで再度 AVPlayerLayer に置き換える処理を行ってもよい
            fatalError("Layer is not AVPlayerLayer. Check that wantsLayer = true and makeBackingLayer() are set properly.")
        }
        playerLayer.player = player
        playerLayer.videoGravity = videoGravity
    }

    var videoBounds: CGRect {
        guard let playerLayer = self.layer as? AVPlayerLayer else { return .zero }
        return playerLayer.videoRect
    }
}

#endif
