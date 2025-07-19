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
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    init(
        model: PDPlayerModel,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.model = model
        self.menuContent = menuContent
    }

    var body: some View {
        VStack(spacing:0) {
            HStack(spacing:0) {
                GlassEffectContainer{
                    HStack(spacing:0){
                        Button {
                            model.togglePlay()
                        } label: {
                            ZStack{
                                Color.clear
                                    .contentShape(Circle())
                                PlayPauseIcon(model: model)
                            }
                        }
                        .frame(width: 36, height: 36)
                        if model.isBuffering{
                            ProgressView()
                                .frame(width: 36, height: 36)
                        }
                    }
                    .glassEffect(.clear)
                }
                .animation(.default,value:model.isBuffering)
                Spacer()
                
                HStack{
                    VideoPlayerDurationView(model:model)
                        .frame(height: 36)
                        .padding(.horizontal)
                        .glassEffect(.clear)
                    Menu {
                        SubtitleMenuView()
                            .pickerStyle(.menu)
                            .menuActionDismissBehavior(.disabled)
                        PlaybackSpeedMenuView()
                            .pickerStyle(.menu)
                            .menuActionDismissBehavior(.disabled)
                        Divider()
                        menuContent()
                    } label: {
                        ZStack{
                            Color.clear
                                .contentShape(Circle())
                            Image(systemName: "ellipsis")
                        }
                    }
                    .frame(width: 36, height: 36)
                    .menuStyle(.button)
                    .glassEffect(.clear,in:.ellipse)
                }
            }
            .tint(foregroundColor.opacity(0.8))
            VideoPlayerSliderView(viewModel: model)
                .frame(height: 36)
                .padding(.vertical,8)
                .contentShape(Rectangle())
        }
        .padding(.horizontal)
    }
}
private struct PlayPauseIcon: View {
    @Environment(\.isPressed) private var isPressed
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    var model: PDPlayerModel
    
    var body: some View {
        Image(systemName: model.isPlaying ? "pause" : "play")
            .symbolVariant(.fill)
            .scaleEffect(isPressed ? 0.8 : 1.0)
            .animation(.default, value: isPressed)
    }
}

#endif
#endif
