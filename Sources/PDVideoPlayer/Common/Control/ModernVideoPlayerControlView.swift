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
                    menuContent()
                    Divider()
                    SubtitleMenuView()
                    PlaybackSpeedMenuView()
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
    private let baseSize:CGFloat = 44
    var body: some View {
        VStack(spacing:8) {
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
                        .frame(width: baseSize, height: baseSize)
                        if model.showBufferingIndicator{
                            ProgressView()
                                .frame(width: baseSize, height: baseSize)
                        }
                    }
                    .glassEffect(.clear)
                    .tint(foregroundColor.opacity(0.8))
                }
                .animation(.default,value:model.showBufferingIndicator)
                Spacer()
                
                Menu {
                    menuContent()
                    Divider()
                    SubtitleMenuView()
                        .pickerStyle(.menu)
                        .menuActionDismissBehavior(.disabled)
                    PlaybackSpeedMenuView()
                        .pickerStyle(.menu)
                        .menuActionDismissBehavior(.disabled)
                } label: {
                    ZStack{
                        Color.clear
                            .contentShape(Circle())
                        Image(systemName: "ellipsis")
                            .foregroundStyle(foregroundColor)
                            .opacity(0.8)
                    }
                }
                .frame(width: baseSize, height: baseSize)
                .menuStyle(.button)
                .glassEffect(.clear,in:.ellipse)
            }
      
            HStack{
                Text(model.currentTime.mmSSString)
                    .monospaced()
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(foregroundColor)
                    .opacity(0.8)
                VideoPlayerSliderView(viewModel: model)
                Text("-\(max(model.duration - model.currentTime, 0).mmSSString)")
                    .monospaced()
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(foregroundColor)
                    .opacity(0.8)
            }
            .padding(.horizontal)
            .frame(height: baseSize)
            .glassEffect(.clear)
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
