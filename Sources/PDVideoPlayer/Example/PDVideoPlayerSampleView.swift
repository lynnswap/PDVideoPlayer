// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import AVKit

#if DEBUG
#Preview{
    NavigationStack{
        PDVideoPlayerSampleView(sampleURL: URL(fileURLWithPath: "/Users/kn/Downloads/ScreenRecording_04-20-2025 17-25-50_1.mov"))
    }
#if os(macOS)
    .frame(width:400,height:600)
#endif
}
#endif

public struct PDVideoPlayerSampleView: View {
    private var sampleURL:URL
    @State private var controlsVisible: Bool = true
    @State private var speed: PlaybackSpeed = .x1_0
    
    public init(
        sampleURL:URL
    ){
        self.sampleURL = sampleURL
    }
    
    public var body: some View {
        PDVideoPlayer(
            url: sampleURL,
            menu: {
                Button(String("Sample 1")) {
                    print("Button Tapped 1")
                }
                Button(String("Sample 2")) {
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
                        .contextMenuProvider{ _ in
                            return uimenu
                        }
                        .scrollViewConfigurator { scrollView in
                            
                        }
                        .skipRippleEffect()
                        .ignoresSafeArea()
#endif
                    VStack(alignment:.center) {
                        if controlsVisible{
#if os(iOS)
                            FastForwardIndicatorView()
#endif
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
#if os(macOS)
                    .padding(.bottom)
#endif
                }
            }
        )
        .playbackSpeed($speed)
        .onLongPress { value in
            print("onLongPress", value)
        }
        .onClose { value in
            print("onClose", value)
        }
        .playerForegroundColor(.white)
        .animation(.smooth(duration:0.12), value: controlsVisible)
        .background(.black)
    }
#if os(iOS)
    private var uimenu:UIMenu{
        let contextMenus :[UIMenuElement] = [
            UIAction(
                title: "save",
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
#endif
}

