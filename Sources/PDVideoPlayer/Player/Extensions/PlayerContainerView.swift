#if os(iOS)
import UIKit
public final class PlayerContainerView: UIView {
    weak var playerView: UIView?
    var contentSize: CGSize?
    override public func layoutSubviews() {
        super.layoutSubviews()
        updateAspectConstraint()
    }
    func updateAspectConstraint() {
        guard let playerView, let contentSize else { return }
        playerView.setConstraintScalledToFit(in: self, size: contentSize)
    }
}
#elseif os(macOS)
import AppKit
public final class PlayerContainerView: NSView {
    weak var playerView: NSView?
    var contentSize: CGSize?
    override public func layout() {
        super.layout()
        updateAspectConstraint()
    }
    func updateAspectConstraint() {
        guard let playerView, let contentSize else { return }
        playerView.setConstraintScalledToFit(in: self, size: contentSize)
    }
}
#endif
