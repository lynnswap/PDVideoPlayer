import SwiftUI

#if swift(>=6.2)
@available(iOS 26.0, macOS 26.0, *)
struct ModernVideoPlayerControlView<MenuContent: View>: View {
    var model: PDPlayerModel
    private let menuContent: () -> MenuContent

    init(
        model: PDPlayerModel,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.model = model
        self.menuContent = menuContent
    }

    var body: some View {
        Color.clear
    }
}
#endif
