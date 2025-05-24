#if os(iOS)
import UIKit

public final class PlayerPanGestureHandler: NSObject, UIGestureRecognizerDelegate {
    /// Called when the close animation should start. The value represents the duration.
    var onClose: (CGFloat) -> Void

    /// The tag of the view to manipulate. Defaults to `1` to preserve existing behaviour.
    let containerViewTag: Int

    private var initialCenter = CGPoint()
    private var isRotatingGestureActive = false
    private var initialGesturePoint = CGPoint.zero

    /// Creates a handler.
    /// - Parameters:
    ///   - containerViewTag: The tag used to locate the target view.
    ///   - onClose: Closure called when the player should be dismissed.
    public init(containerViewTag: Int = 1, onClose: @escaping (CGFloat) -> Void) {
        self.containerViewTag = containerViewTag
        self.onClose = onClose
    }

    @objc public func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard let scrollView = recognizer.view as? UIScrollView,
              let containerView = scrollView.viewWithTag(containerViewTag) else { return }

        if scrollView.zoomScale > scrollView.minimumZoomScale {
            recognizer.isEnabled = false
            return
        }

        switch recognizer.state {
        case .began:
            initialCenter = containerView.center
            let startInScroll = recognizer.location(in: scrollView)
            let startInContainer = scrollView.convert(startInScroll, to: containerView)
            initialGesturePoint = CGPoint(x: containerView.center.x - startInContainer.x,
                                          y: containerView.center.y - startInContainer.y)
            containerView.setAnchorPoint(anchorPointInContainerView: startInContainer, forView: scrollView)
        case .changed:
            let translation = recognizer.translation(in: scrollView)
            if isRotatingGestureActive || abs(translation.y) >= 20 {
                isRotatingGestureActive = true
                containerView.center = CGPoint(x: initialCenter.x + translation.x,
                                               y: initialCenter.y + translation.y)
                let angleFactor = initialGesturePoint.x > 0 ? -1.0 : 1.0
                let angle = min(translation.y / scrollView.bounds.height, 1.0) * CGFloat.pi / 4.0 * angleFactor
                containerView.transform = CGAffineTransform(rotationAngle: angle)
            }
        case .ended:
            isRotatingGestureActive = false
            let velocity = recognizer.velocity(in: scrollView)
            if abs(velocity.x) < abs(velocity.y) && abs(velocity.y) > 500 {
                let predictedEndCenter = CGPoint(
                    x: containerView.center.x + velocity.x * UIScrollView.DecelerationRate.normal.rawValue,
                    y: containerView.center.y + velocity.y * UIScrollView.DecelerationRate.normal.rawValue
                )
                let speed = abs(velocity.y) / scrollView.bounds.height
                var stoptime = (CGFloat(2.8) / speed)
                if stoptime > 2.5 {
                    stoptime = CGFloat(2.5)
                } else if stoptime < 0.2 {
                    stoptime = 0.2
                }
                onClose(stoptime * 0.5)

                UIView.animate(withDuration: stoptime, delay: 0, options: .curveLinear, animations: {
                    containerView.center = CGPoint(
                        x: self.initialCenter.x + predictedEndCenter.x,
                        y: self.initialCenter.y + predictedEndCenter.y
                    )
                    containerView.alpha = 0
                    let angleFactor = self.initialGesturePoint.x > 0 ? -1.0 : 1.0
                    let angle = min(predictedEndCenter.y / scrollView.bounds.height, 1.0) * CGFloat.pi / 3.0 * angleFactor
                    containerView.transform = CGAffineTransform(rotationAngle: angle)
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    containerView.transform = .identity
                    containerView.center = self.initialCenter
                })
            }
        default:
            break
        }
    }

    @objc public func handlePanGestureUpDown(_ recognizer: UIPanGestureRecognizer) {
        guard let scrollView = recognizer.view as? UIScrollView,
              let containerView = scrollView.viewWithTag(containerViewTag) else { return }

        if scrollView.zoomScale > scrollView.minimumZoomScale {
            recognizer.isEnabled = false
            return
        }

        switch recognizer.state {
        case .began:
            initialCenter = containerView.center
        case .changed:
            let translation = recognizer.translation(in: scrollView)
            containerView.center = CGPoint(x: initialCenter.x, y: initialCenter.y + translation.y)
        case .ended:
            let velocity = recognizer.velocity(in: scrollView)
            if abs(velocity.x) < abs(velocity.y) && abs(velocity.y) > 500 {
                let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
                let predictedEndCenter = CGPoint(
                    x: containerView.center.x + velocity.x * decelerationRate,
                    y: containerView.center.y + velocity.y * decelerationRate
                )
                let speed = abs(velocity.y) / scrollView.bounds.height
                var stoptime = (CGFloat(2.0) / speed)
                if stoptime > 2.0 {
                    stoptime = CGFloat(2.5)
                } else if stoptime < 0.18 {
                    stoptime = 0.15
                }
                onClose(stoptime * 0.5)

                UIView.animate(withDuration: stoptime, delay: 0, options: .curveLinear, animations: {
                    containerView.center = CGPoint(
                        x: self.initialCenter.x,
                        y: self.initialCenter.y + predictedEndCenter.y)
                    containerView.alpha = 0
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    containerView.transform = CGAffineTransform.identity
                    containerView.center = self.initialCenter
                })
            }
        default:
            break
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scrollView = gestureRecognizer.view as? UIScrollView else { return false }

        if scrollView.zoomScale <= scrollView.minimumZoomScale {
            if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                let translation = panGestureRecognizer.translation(in: scrollView)
                return abs(translation.y) <= abs(translation.x)
            }
        }
        return scrollView.zoomScale <= scrollView.minimumZoomScale && !isRotatingGestureActive
    }
}
#endif
