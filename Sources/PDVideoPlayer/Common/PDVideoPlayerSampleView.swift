// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import AVKit

#if DEBUG
private let sampleURL = URL(fileURLWithPath: "/Users/kn/Downloads/ScreenRecording_04-20-2025 17-25-50_1.mov")
struct ContentView: View {
    @State private var player = AVPlayer(url:sampleURL)
    @State private var isMuted: Bool = true
    @State private var controlsVisible: Bool = true
    
    var body: some View {
        PDVideoPlayer(
            player: player,
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
                        .onTap { inside in
                            print("onTap", inside)
                        }
                        .onPresentationSizeChange({ view, size in
                            
                        })
                    
#if os(iOS)
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
                        .scrollViewConfigurator { scrollView in
                            
                        }
                        .skipRippleEffect()
#endif
                        .ignoresSafeArea()
                    VStack(alignment:.center) {
                        if controlsVisible{
                            proxy.navigation
                            Spacer()
                            proxy.control
#if os(macOS)
                                .trackpadSwipeOverlay()
                                .buttonStyle(.plain)
                                .padding(.horizontal)
#endif
                                .frame(maxWidth: 500,alignment: .center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                }
            }
        )
        .isMuted($isMuted)
        .onLongPress { value in
            print("onLongPress", value)
        }
        .onClose { value in
            print("onClose", value)
        }
        .playerForegroundColor(.white)
        .animation(.smooth(duration:0.12), value: controlsVisible)
    }
}

#Preview{
    ContentView()
#if os(macOS)
        .frame(width:400,height:600)
#endif
}
#endif
