#if canImport(UIKit)
typealias PlatformView = UIView
#elseif canImport(AppKit)
typealias PlatformView = NSView
#endif

extension PlatformView {
    /// Constrain the view to fit inside its container while preserving aspect ratio.
    /// - Parameters:
    ///   - container: The container view to fit within.
    ///   - contentSize: The natural size of the content for calculating aspect ratio.
    func setConstraintScalledToFit(
        container containerView: PlatformView,
        size contentSize: CGSize
    ) {
        containerView.constraints.forEach { $0.isActive = false }
        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        let widthLimit  = self.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor)
        let heightLimit = self.heightAnchor.constraint(lessThanOrEqualTo: containerView.heightAnchor)
        NSLayoutConstraint.activate([widthLimit, heightLimit])

        let aspectRatio = contentSize.width / contentSize.height
        let aspect = self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: aspectRatio)
        NSLayoutConstraint.activate([aspect])

        let widthEqual = self.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        widthEqual.priority = .defaultLow
        let heightEqual = self.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        heightEqual.priority = .defaultLow
        NSLayoutConstraint.activate([widthEqual, heightEqual])
    }
}
