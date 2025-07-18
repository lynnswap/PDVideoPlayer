#if os(iOS)
import SwiftUI
import AVKit

public typealias PDVideoPlayerRepresentable = PDVideoPlayerView_iOS

public struct PDVideoPlayerView_iOS: UIViewRepresentable {
    public typealias ContextMenuProvider = (CGPoint) -> UIMenu?
    public typealias ScrollViewConfigurator = (UIScrollView) -> Void
    public typealias PresentationSizeAction = (_ view: UIView, _ size: CGSize) -> Void


    public var model: PDPlayerModel
    let scrollViewConfigurator: ScrollViewConfigurator?
    let contextMenuProvider: ContextMenuProvider?
    let onPresentationSizeChange: PresentationSizeAction?
    let onTap: VideoPlayerTapAction?
 
    public init(
        model: PDPlayerModel,
        scrollViewConfigurator: ScrollViewConfigurator? = nil,
        contextMenuProvider: ContextMenuProvider? = nil,
        onPresentationSizeChange: PresentationSizeAction? = nil,
        onTap: VideoPlayerTapAction? = nil

    ) {
        self.model = model
        self.scrollViewConfigurator = scrollViewConfigurator
        self.contextMenuProvider = contextMenuProvider
        self.onPresentationSizeChange = onPresentationSizeChange
        self.onTap = onTap
    }
    @Environment(\.videoPlayerOnLongPress) private var onLongPress

    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = model.scrollView
        
        let playerView = model.setupPlayer()
        context.coordinator.playerView = playerView

        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
#if swift(>=6.2)
        if #available(iOS 26.0,macOS 26.0, *) {
            scrollView.topEdgeEffect.isHidden = true
            scrollView.bottomEdgeEffect.isHidden = true
            scrollView.leftEdgeEffect.isHidden = true
            scrollView.rightEdgeEffect.isHidden = true
        }
#endif
       
        let containerView = PlayerContainerView()
        context.coordinator.containerView = containerView
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
        
        if let playerItem = model.player.currentItem {
            context.coordinator.presentationSizeObservation?.invalidate()
            context.coordinator.presentationSizeObservation = nil
            context.coordinator.presentationSizeObservation = playerItem.observe(\.presentationSize, options: [.new, .initial]) { item, _ in
                let size = item.presentationSize
                if size.width > 0, size.height > 0 {
                    Task { @MainActor in
                        context.coordinator.presentationSizeObservation?.invalidate()
                        context.coordinator.presentationSizeObservation = nil
                        containerView.playerView = playerView.view
                        containerView.contentSize = size
                        containerView.updateAspectConstraint()
                        onPresentationSizeChange?(playerView.view, size)
                    }
                }
            }
        }
        if contextMenuProvider != nil {
            let contextMenuInteraction = UIContextMenuInteraction(delegate: context.coordinator)
            playerView.view.addInteraction(contextMenuInteraction)
        }
        scrollViewConfigurator?(scrollView)

        return scrollView
    }
    public func updateUIView(_ uiView: UIScrollView, context: Context) {}

    public static func dismantleUIView(
        _ uiView: Self.UIViewType,
        coordinator: Self.Coordinator
    ){
        coordinator.presentationSizeObservation?.invalidate()
        coordinator.presentationSizeObservation = nil
    }
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    public class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: PDVideoPlayerRepresentable
        weak var playerView:AVPlayerViewController?
        weak var containerView: PlayerContainerView?
        var presentationSizeObservation: NSKeyValueObservation?
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
