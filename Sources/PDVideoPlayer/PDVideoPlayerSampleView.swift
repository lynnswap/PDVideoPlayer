// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import AVKit


private let sampleURL = URL(fileURLWithPath: "/Users/kn/Downloads/ScreenRecording_04-20-2025 17-25-50_1.mov")

#if os(macOS)
struct ContentView: View {
    @State private var player = AVPlayer(url:sampleURL)
    @State private var isMuted: Bool = true
    @State private var controlsVisible: Bool = true
    @State private var originalRate: Float = 1.0

    var body: some View {
        PDVideoPlayer(
            url: sampleURL,
            menu: {
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
                        .ignoresSafeArea()
                    proxy.control
                    VStack {
                        proxy.navigation
                        Spacer()
                    }
                }
            }
        )

        .isMuted($isMuted)
        .controlsVisible($controlsVisible)
        .originalRate($originalRate)
        .longpressAction { value in
            print("longpressAction",value)
        }
        .closeAction { value in
            print("closeAction",value)
        }
    }
}
#endif


#if os(iOS) && DEBUG
private struct ContentView: View {
    @State private var isMuted: Bool = true
    @State private var controlsVisible: Bool = true
    @State private var originalRate: Float = 1.0

    var body:some View{
        PDVideoPlayer(
            url: sampleURL,
            menu: {
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
                        .panGesture(.rotation)
                        .contextMenuProvider{ location in
                            let contextMenus :[UIMenuElement] = [
                                UIAction(
                                    title: String(localized:"save"),
                                    image: UIImage(systemName: "square.and.arrow.down")
                                ) { _ in
                                    print("save")
                                }
                            ]
                            return UIMenu(
                                title: "",
                                children: contextMenus
                            )
                        }
                        .rippleEffect()
                        .ignoresSafeArea()
                    proxy.control
                    VStack {
                        proxy.navigation
                        Spacer()
                    }
                }
            }
        )
        .isMuted($isMuted)
        .controlsVisible($controlsVisible)
        .originalRate($originalRate)
        .longpressAction { value in
            print("longpressAction",value)
        }
        .closeAction { value in
            print("closeAction",value)
        }
    }
}
#endif
#Preview{
    ContentView()
#if os(macOS)
        .frame(width:400,height:600)
#endif
}
