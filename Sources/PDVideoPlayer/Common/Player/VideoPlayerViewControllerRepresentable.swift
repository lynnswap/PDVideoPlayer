//
//  VideoPlayerViewControllerRepresentable.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/13.
//


import SwiftUI
import AVKit
#if os(macOS)
import AppKit
#endif



#if os(macOS)

public typealias PDVideoPlayerRepresentable = PDVideoPlayerView_macOS

public struct PDVideoPlayerView_macOS<MenuContent: View>: NSViewRepresentable {
    public typealias ContextMenuProvider = (CGPoint) -> NSMenu?
    public typealias PlayerViewConfigurator = (PlayerNSView) -> Void
    public typealias PresentationSizeAction = ((_ view: NSView, _ size: CGSize) -> Void)
    
    var model: PDPlayerModel
    let menuContent: () -> MenuContent
    let onPresentationSizeChange: PresentationSizeAction?
    let playerViewConfigurator: PlayerViewConfigurator?
    let onTap: VideoPlayerTapAction?
    
    public init(
        model: PDPlayerModel,
        playerViewConfigurator:PlayerViewConfigurator? = nil,
        onPresentationSizeChange: PresentationSizeAction? = nil,
        onTap: VideoPlayerTapAction? = nil,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.model = model
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

        let singleClickGestureRecognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        singleClickGestureRecognizer.numberOfClicksRequired = 1
        playerView.addGestureRecognizer(singleClickGestureRecognizer)

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


        if #available(macOS 14.4, *) {
            let hostingMenu = NSHostingMenu(rootView: menuContent())
            playerView.menu = hostingMenu
        }
        playerViewConfigurator?(playerView)


        model.player.appliesMediaSelectionCriteriaAutomatically = false

        if onPresentationSizeChange != nil, let playerItem = model.player.currentItem {
            context.coordinator.presentationSizeObservation?.invalidate()
            context.coordinator.presentationSizeObservation = nil
            context.coordinator.presentationSizeObservation = playerItem.observe(\.presentationSize, options: [.new, .initial]) { item, change in
                let size = item.presentationSize
                if size.width > 0, size.height > 0 {
                    Task{ @MainActor in
                        context.coordinator.presentationSizeObservation?.invalidate()
                        context.coordinator.presentationSizeObservation = nil
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

#else
public typealias PDVideoPlayerRepresentable = PDVideoPlayerView_iOS
public struct PDVideoPlayerView_iOS: UIViewRepresentable {
    public typealias ContextMenuProvider = (CGPoint) -> UIMenu?
    public typealias ScrollViewConfigurator = (UIScrollView) -> Void

    
    var model: PDPlayerModel
    let closeGesture: PDVideoPlayerCloseGesture
    let scrollViewConfigurator: ScrollViewConfigurator?
    let contextMenuProvider: ContextMenuProvider?
    let onTap: VideoPlayerTapAction?
 
    public init(
        model: PDPlayerModel,
        closeGesture: PDVideoPlayerCloseGesture = .rotation,
        scrollViewConfigurator: ScrollViewConfigurator? = nil,
        contextMenuProvider: ContextMenuProvider? = nil,
        onTap: VideoPlayerTapAction? = nil

    ) {
        self.model = model
        self.closeGesture = closeGesture
        self.scrollViewConfigurator = scrollViewConfigurator
        self.contextMenuProvider = contextMenuProvider
        self.onTap = onTap
    }
    @Environment(\.videoPlayerOnLongPress) private var onLongPress

    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = model.scrollView
        if context.coordinator.dismantled{
            return scrollView
        }
        
        let playerView = model.setupPlayer()
        context.coordinator.playerView = playerView
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
       
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.tag = 1
        scrollView.addSubview(containerView)
        
        
        playerView.videoGravity = .resizeAspect
        playerView.showsPlaybackControls = false
        playerView.view.backgroundColor = .clear
        playerView.canStartPictureInPictureAutomaticallyFromInline = true
        playerView.allowsPictureInPicturePlayback = true
        
        
        playerView.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(playerView.view)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            
            playerView.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            playerView.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            playerView.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            playerView.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            playerView.view.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            playerView.view.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])

        if ProcessInfo.processInfo.isiOSAppOnMac {
            // シングルタップジェスチャ
            let singleTapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap_mac(_:)))
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            scrollView.addGestureRecognizer(singleTapGestureRecognizer)
        }else{
            // ダブルタップジェスチャ
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: model, action: #selector(model.handleDoubleTap(_:)))
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
            
            // シングルタップジェスチャ
            let singleTapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap(_:)))
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
            scrollView.addGestureRecognizer(singleTapGestureRecognizer)
        }

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPressGestureRecognizer.delegate = context.coordinator
        longPressGestureRecognizer.minimumPressDuration = 0.5
        scrollView.addGestureRecognizer(longPressGestureRecognizer)
        
        if contextMenuProvider != nil{
            let contextMenuInteraction = UIContextMenuInteraction(delegate: context.coordinator)
            playerView.view.addInteraction(contextMenuInteraction)
        }
        switch closeGesture {
        case .rotation:
            let panGestureRecognizer = UIPanGestureRecognizer(target: model, action: #selector(PDPlayerModel.handlePanGesture(_:)))
            panGestureRecognizer.delegate = model
            scrollView.isUserInteractionEnabled = true
            scrollView.addGestureRecognizer(panGestureRecognizer)
        case .vertical:
            let panGestureRecognizer = UIPanGestureRecognizer(target: model, action: #selector(PDPlayerModel.handlePanGestureUpDown(_:)))
            panGestureRecognizer.delegate = model
            scrollView.isUserInteractionEnabled = true
            scrollView.addGestureRecognizer(panGestureRecognizer)
        case .none:
            break
        }
        scrollViewConfigurator?(scrollView)

        return scrollView
    }
    public func updateUIView(_ uiView: UIScrollView, context: Context) {}

    public static func dismantleUIView(
        _ uiView: Self.UIViewType,
        coordinator: Self.Coordinator
    ){
        coordinator.dismantled = true
    }
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    public class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: PDVideoPlayerRepresentable
        var dismantled:Bool = false
        weak var playerView:AVPlayerViewController?
        init(_ parent: PDVideoPlayerRepresentable) {
            self.parent = parent
        }
        
        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
        public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scale == 1.0 {
                // Enable the pan gesture recognizer
                scrollView.gestureRecognizers?.forEach { recognizer in
                    if let panRecognizer = recognizer as? UIPanGestureRecognizer {
                        panRecognizer.isEnabled = true
                    }
                }
            }
        }

        @objc func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
            if self.parent.model.doubleTapCount == 0 {
                var inside = true
                if let playerView {
                    let location = recognizer.location(in: playerView.view)
                    let videoRect = playerView.videoBounds
                    inside = videoRect.contains(location)
                }
                self.parent.onTap?(inside)
            }
        }
        @objc func handleSingleTap_mac(_ recognizer: UITapGestureRecognizer) {
            guard let playerView else {
                parent.onTap?(true)
                return
            }
            let locationInPlayerView = recognizer.location(in: playerView.view)
            let videoRect = playerView.videoBounds
            let inside = videoRect.contains(locationInPlayerView)
            parent.onTap?(inside)
        }
        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            let model = parent.model
            
            switch recognizer.state {
            case .began:
                // 今の再生レートを保持
                self.parent.model.originalRate = model.player.rate
                // もし再生中であれば（rateが0でなければ）
                if self.parent.model.isPlaying {
                    // 現在のレートの2倍にする
                    self.parent.model.player.rate = min(self.parent.model.originalRate * 2.0, 2.0)
                    self.parent.model.isLongpress = true
                    self.parent.onLongPress?(true)
                }
            case .ended, .cancelled, .failed:
                // 長押し終了時に元のレートに戻す
                self.parent.model.player.rate = self.parent.model.originalRate
                self.parent.model.isLongpress = false
                self.parent.onLongPress?(false)
            default:
                break
            }
        }
    }

}


class PlayerUIView: UIView,UIGestureRecognizerDelegate {
    func setPlayer(_ player: AVPlayer,
                   _ videoGravity: AVLayerVideoGravity) -> AVPlayerLayer {
        self.playerLayer.player = player
        self.playerLayer.videoGravity = videoGravity
        return self.playerLayer
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
}
extension PDVideoPlayerRepresentable.Coordinator: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool
    {
        guard gestureRecognizer is UILongPressGestureRecognizer,
              let playerView else {
            return true
        }
        let locationInPlayerView = touch.location(in: playerView.view)

        let height = playerView.view.bounds.height - playerView.view.safeAreaInsets.bottom
        let adjustInset = min(ADJSUT_GESTURE_INSET,height / 5)
        
        let bottomSafeAreaStart = height - adjustInset
        if locationInPlayerView.y >= bottomSafeAreaStart {
            return true
        }

        let videoRect = playerView.videoBounds
        if videoRect.contains(locationInPlayerView) {
            return false
        }
        return true
    }
}
private let ADJSUT_GESTURE_INSET :CGFloat = 150
extension PDVideoPlayerRepresentable.Coordinator: UIContextMenuInteractionDelegate {
    
    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let playerView else { return nil }
        
        let height = playerView.view.bounds.height - playerView.view.safeAreaInsets.bottom
        let adjustInset = min(ADJSUT_GESTURE_INSET,height / 5)
        
        let bottomSafeAreaStart = height - adjustInset
        
        if location.y >= bottomSafeAreaStart {
            return nil
        }
        
        let videoRect = playerView.videoBounds
        guard videoRect.contains(location) else {
            return nil
        }
        
        if let userProvidedMenu = parent.contextMenuProvider?(location) {
            return UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: nil
            ) { _ in
                return userProvidedMenu
            }
        } else{
            return nil
        }
    }
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addAnimations {
            animator.previewViewController?.view.backgroundColor = .clear
        }
    }
}
#endif
