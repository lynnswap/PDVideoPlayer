#if os(macOS)
import SwiftUI

public extension PDVideoPlayerRepresentable {
    func playerViewConfigurator(_ configurator: @escaping PlayerViewConfigurator) -> Self {
        Self(model: self.model, playerViewConfigurator: configurator, resizeAction: self.resizeAction, menuContent: self.menuContent)
    }

    func resizeAction(_ action: @escaping ResizeAction) -> Self {
        Self(model: self.model, playerViewConfigurator: self.playerViewConfigurator, resizeAction: action, menuContent: self.menuContent)
    }

    func playerOverlay( _ overlay:some View) -> Self {
        let configurator = self.playerViewConfigurator
        let newConfigurator: PlayerViewConfigurator = { view in
            configurator?(view)
            if let customView = view as? CustomAVPlayerView {
                if let contentOverlayView = customView.contentOverlayView {
                   let overlayHostingView = NSHostingView(rootView: overlay)
                   contentOverlayView.addSubview(overlayHostingView)
                   overlayHostingView.translatesAutoresizingMaskIntoConstraints = false
                   overlayHostingView.topAnchor.constraint(equalTo: contentOverlayView.topAnchor).isActive = true
                   overlayHostingView.trailingAnchor.constraint(equalTo: contentOverlayView.trailingAnchor).isActive = true
                   overlayHostingView.bottomAnchor.constraint(equalTo: contentOverlayView.bottomAnchor).isActive = true
                   overlayHostingView.leadingAnchor.constraint(equalTo: contentOverlayView.leadingAnchor).isActive = true
               }
            }
        }
        return Self(model: self.model, playerViewConfigurator: newConfigurator, resizeAction: self.resizeAction, menuContent: self.menuContent)
    }
}
#endif
