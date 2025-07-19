import SwiftUI

#if swift(>=6.2)


#if os(macOS)
@available(iOS 26.0, macOS 26.0, *)
struct ModernVideoPlayerControlView<MenuContent: View>: View {
    var model: PDPlayerModel
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor

    private let menuContent: () -> MenuContent

    public init(
        model: PDPlayerModel,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.model = model
        self.menuContent = menuContent
    }

    public var body: some View {
        VStack(spacing:0){
            HStack(alignment: .bottom) {
                PlayPauseButton(model:model)
                    .frame(width: 60, height: 40)
                Spacer()
                VideoPlayerDurationView(model:model)
                Menu{
                    SubtitleMenuView()
                    PlaybackSpeedMenuView()
                    Divider()
                    menuContent()
                }label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(foregroundColor)
                }
            }
            VideoPlayerSliderView(viewModel: model)
        }
        .contentShape(Rectangle())
    }
}
#else

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
        VStack {
            HStack(alignment: .bottom, spacing: 0) {
                PlayPauseButton(model:model)
                    .frame(width: 90, height: 60)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                Spacer()
                
                ZStack(alignment:.bottomTrailing){
                    VideoPlayerDurationView(model:model)
                        .padding(.trailing,48)
                        .padding(.bottom,1.5)
                    
                    VideoPlayerMenuView {
                        menuContent()
                    }
                }
                .frame(height:60)
            }
            VideoPlayerSliderView(viewModel: model)
                .frame(height: 36)
                .padding(.horizontal)
                .padding(.vertical,8)
                .contentShape(Rectangle())
        }
    }
}
#endif
#endif
