//
//  VideoPlayerControlViewLegacy.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/26.
//

import SwiftUI
#if os(macOS)
public struct VideoPlayerControlViewLegacy<MenuContent: View>: View {
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
public struct VideoPlayerControlViewLegacy<MenuContent: View>: View {
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
private struct VideoPlayerDurationView: View {
    var model:PDPlayerModel
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    var body:some View{
        Text("\(formatTime(model.currentTime)) / \(formatTime(model.duration))")
            .monospaced()
            .font(.caption)
            .foregroundStyle(foregroundColor)
            .opacity(0.8)
    }
    // MARK: - 時刻表示フォーマッタ
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && time >= 0 else { return "00:00" }
        let totalSec = Int(time)
        let minutes = totalSec / 60
        let seconds = totalSec % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
public struct PlayPauseButton: View{
    public var model: PDPlayerModel
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    
    public init(
        model:PDPlayerModel
    ){
        self.model = model
    }
    public var body:some View{
        Button {
            model.togglePlay()
        } label: {
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .contentShape(Rectangle())
                HStack(spacing:12){
                    PlayPauseIcon(model: model)
                    if model.isBuffering{
#if os(macOS)
                    ProgressView()
                        .opacity(0)
                        .overlay {
                            foregroundColor.opacity(0.8).mask {
                                ProgressView()
                            }
                        }
                        .controlSize(.small)
#else
                    ProgressView()
                        .tint(foregroundColor.opacity(0.8))
#endif
                    }
                    Spacer(minLength: 0)
                }
                .animation(.smooth(duration:0.2),value:model.isBuffering)
            }
        }
        .buttonStyle(PlayButtonStyle())
    }
}
struct PlayPauseIcon: View {
    @Environment(\.isPressed) private var isPressed
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    var model: PDPlayerModel
    
    var body: some View {
        Image(systemName: model.isPlaying ? "pause" : "play")
            .symbolVariant(.fill)
            .imageScale(.large)
            .foregroundStyle(foregroundColor)
            .opacity(0.8)
            .scaleEffect(isPressed ? 0.8 : 1.0)
            .animation(.default, value: isPressed)
    }
}

struct PlayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.isPressed, configuration.isPressed)
    }
}

extension EnvironmentValues {
    /// Define `isPressed` using the `@Entry` macro available in Xcode 16.
    @Entry var isPressed: Bool = false
}
