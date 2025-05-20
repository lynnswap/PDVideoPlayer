// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import AVKit

#if os(macOS)
struct PDVideoPlayerSampleView: View {
    
    var player :AVPlayer
    
    init(
        url:URL
    ) {
        self.player = AVPlayer(url:url)
    }
    init(
        player:AVPlayer
    ) {
        self.player = player
    }
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        
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

#endif
#if DEBUG
private let videoURL = URL(fileURLWithPath: "/Users/kn/Downloads/ScreenRecording_04-20-2025 17-25-50_1.mov")

private struct ContentView: View {
    @State private var isMuted: Bool = true
    @State private var controlsVisible: Bool = true
    @State private var originalRate: Float = 1.0

    var body:some View{
        PDVideoPlayer(
            url: videoURL,
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
        .controlsVisible($controlsVisible)
        .originalRate($originalRate)
        .longpressAction { value in
            print("longpressAction",value)
        }
        .closeAction {
            
        }
    }
}

#Preview{
    ContentView()
}

#endif
