// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import AVKit

#if os(macOS)
public struct PDVideoPlayer: View {
    
    var player :AVPlayer
    
    public init(
        url:URL
    ) {
        self.player = AVPlayer(url:url)
    }
    public init(
        player:AVPlayer
    ) {
        self.player = player
    }
    @Environment(\.scenePhase) private var scenePhase
    public var body: some View {
        
        PDVideoPlayerRepresentable(
            player: player,
            menuContent:{
                Button{
                    
                }label:{
                    Text("test")
                }
            }
        )
    }
}
#else

public struct PDVideoPlayer: View {

    @State private var playerViewModel :PDPlayerModel
    
    public init(
        url:URL
    ) {
        _playerViewModel = State(initialValue: PDPlayerModel(url:url))
    }
    public init(
        player:AVPlayer
    ) {
        _playerViewModel = State(initialValue:PDPlayerModel(player:player))
    }
    @State private var isMuted: Bool = false
    @State private var isLongpress: Bool = false
    @State private var controlsVisible: Bool = true
    @State private var originalRate: Float = 1.0
    private let closeAction = VideoPlayerCloseAction({})
   
    @Environment(\.scenePhase) private var scenePhase
    public var body: some View {
        
        PDVideoPlayerView(
            model: playerViewModel,
            menuContent: {
                Button("Sample 1") {
                    print("Button Tapped 1")
                }
                Button("Sample 2") {
                    print("Button Tapped 2")
                }
            },
            content: { proxy in
                ZStack {
                    proxy.player
                        .rippleEffect()
                        .ignoresSafeArea()
                    proxy.control
                }
            }
        )
        .isMuted($isMuted)
        .isLongpress($isLongpress)
        .controlsVisible($controlsVisible)
        .originalRate($originalRate)
        .closeAction(closeAction)
    }
}
#endif
#if DEBUG
private let videoURL = URL(fileURLWithPath: "/Users/kn/Downloads/ScreenRecording_04-20-2025 17-25-50_1.mov")
#Preview{
    PDVideoPlayerWrapper()
}
public struct PDVideoPlayerWrapper: View {
    @State private var isMuted: Bool = true
    @State private var isLongpress: Bool = false
    @State private var controlsVisible: Bool = true
    @State private var originalRate: Float = 1.0
    private let closeAction = VideoPlayerCloseAction({})

    public init(){}
    public var body:some View{
        PDVideoPlayer(url:videoURL)
            .environment(\.videoPlayerIsMuted, $isMuted)
            .environment(\.videoPlayerIsLongpress, $isLongpress)
            .environment(\.videoPlayerControlsVisible, $controlsVisible)
            .environment(\.videoPlayerOriginalRate, $originalRate)
            .environment(\.videoPlayerCloseAction, closeAction)
    }
}
//@main
struct tweetpdApp: App {
    var body: some Scene {
        WindowGroup {
            PDVideoPlayerWrapper()
        }
    }
}
#endif
