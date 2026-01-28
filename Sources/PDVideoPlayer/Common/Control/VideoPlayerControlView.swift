import SwiftUI

public struct VideoPlayerControlView<MenuContent: View>: View {
    var model: PDPlayerModel
    private let menuContent: () -> MenuContent

    public init(
        model: PDPlayerModel,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.model = model
        self.menuContent = menuContent
    }

    public var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            ModernVideoPlayerControlView(model: model, menuContent: menuContent)
        } else {
            VideoPlayerControlViewLegacy(model: model, menuContent: menuContent)
        }
    }
}
