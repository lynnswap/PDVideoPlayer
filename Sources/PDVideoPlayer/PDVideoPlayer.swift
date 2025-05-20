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
        
        PDVideoPlayerView(
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
    @State private var controllerModel = PDPlayerControllerModel(isMuted: false)
   
    @Environment(\.scenePhase) private var scenePhase
    public var body: some View {
        ZStack{
            Color.black
                .ignoresSafeArea()
            PDVideoPlayerView(model: playerViewModel)
                .rippleEffect(playerViewModel) { store in
                    playerViewModel.rippleStore = store
                }
                .ignoresSafeArea()
            
            VideoPlayerControlView(model: playerViewModel) {
                Toggle(isOn: Bindable(playerViewModel).isLooping) {
                    Text("ループ再生")
                }
                Button("サンプルボタン") {
                    print("Button Tapped")
                }
            }
        }
        
        .environment(controllerModel)
    }
}
#endif
#if DEBUG
private let videoURL = URL(fileURLWithPath: "/Users/kn/Downloads/ScreenRecording_04-20-2025 17-25-50_1.mov")
#Preview{
    PDVideoPlayerWrapper()
}
public struct PDVideoPlayerWrapper: View {
    @State private var controllerModel = PDPlayerControllerModel(isMuted:true)
    
    public init(){}
    public var body:some View{
        PDVideoPlayer(url:videoURL)
            .environment(controllerModel)
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
