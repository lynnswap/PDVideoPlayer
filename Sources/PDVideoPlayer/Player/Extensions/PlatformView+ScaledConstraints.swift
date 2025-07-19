import SwiftUI

#if canImport(UIKit)
typealias PlatformView = UIView
#elseif canImport(AppKit)
typealias PlatformView = NSView
#endif

extension PlatformView {
    /// Constrain the view to fit inside its container while preserving aspect ratio.
    /// - Parameters:
    ///   - containerView: The container view to fit within.
    ///   - contentSize: The natural size of the content for calculating aspect ratio.
    func setConstraintScalledToFit(
        in containerView: PlatformView,
        size contentSize: CGSize
    ) {
        guard contentSize.width > 0, contentSize.height > 0 else { return }
        
        (containerView.constraints + self.constraints)
            .filter { $0.firstItem === self || $0.secondItem === self }
            .forEach { $0.isActive = false }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        let aspectRatio = contentSize.width / contentSize.height
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalTo: self.heightAnchor,
                                        multiplier: aspectRatio)
        ])
        
        let wLimit = self.widthAnchor .constraint(lessThanOrEqualTo: containerView.widthAnchor)
        let hLimit = self.heightAnchor.constraint(lessThanOrEqualTo: containerView.heightAnchor)
        NSLayoutConstraint.activate([wLimit, hLimit])
        
        let containerAspect = containerView.bounds.width / max(containerView.bounds.height, 1)
        if aspectRatio > containerAspect {
            let wFit = self.widthAnchor .constraint(equalTo: containerView.widthAnchor)
            wFit.priority = .defaultHigh
            NSLayoutConstraint.activate([wFit])
        } else {
            let hFit = self.heightAnchor.constraint(equalTo: containerView.heightAnchor)
            hFit.priority = .defaultHigh
            NSLayoutConstraint.activate([hFit])
        }
    }
}
