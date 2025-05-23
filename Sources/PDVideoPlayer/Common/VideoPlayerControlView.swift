//
//  VideoPlayerControlView.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/26.
//

import SwiftUI
#if os(macOS)
public struct VideoPlayerControlView<MenuContent: View>: View {
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
                    .frame(width: 40, height: 40)
                Spacer()
                VideoPlayerDurationView(model:model)
                Menu{
                    SubtitleMenuView()
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
        .overlay(
            TrackpadSwipeOverlay(model: model)
                .allowsHitTesting(false)
        )
    }
}

struct TrackpadSwipeOverlay: NSViewRepresentable {
    var model: PDPlayerModel

    @MainActor
    class Coordinator {
        var monitor: Any?
        var model: PDPlayerModel
        init(model: PDPlayerModel) {
            self.model = model
        }

        func install() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self else { return event }
                if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
                    model.slider.scrollWheel(with: event)
                    return nil
                }
                return event
            }
        }

        func uninstall() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.install()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }
}
#else
public struct VideoPlayerControlView<MenuContent: View>: View {
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
                    
                    Menu {
                        SubtitleMenuView()
                            .pickerStyle(.menu)
                            .menuActionDismissBehavior(.disabled)
                        Divider()
                        menuContent()
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            Rectangle()
                                .foregroundStyle(.clear)
                                .contentShape(Rectangle())
                            Image(systemName: "ellipsis.circle")
                                .font(.callout)
                                .foregroundStyle(foregroundColor)
                                .opacity(0.8)
                                .padding(.top, 12)
                            
                        }
                        
                        .frame(width: 60, height: 60)
                        .padding(.trailing)
                        .padding(.leading,4)
                        .contentShape(Rectangle())
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
                        ProgressView()
                            .tint(foregroundColor.opacity(0.8))
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
private struct IsPressedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isPressed: Bool {
        get { self[IsPressedKey.self] }
        set { self[IsPressedKey.self] = newValue }
    }
}
