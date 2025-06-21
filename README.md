# PDVideoPlayer

**PDVideoPlayer** is a Swift Package that provides a customizable video player component for SwiftUI on both iOS and macOS. It wraps `AVPlayer` inside a SwiftUI view and exposes convenient APIs for common playback controls.

## Features

- Universal support for **iOS** and **macOS** using the same code base.
- Picture-in-Picture on iOS via `PiPManager`.
- AirPlay route picker for streaming to external displays.
- Custom context menus on iOS via `contextMenuProvider`.
- Gesture handling including double-tap skip with ripple effects, long press speed changes.
- Optional overlay to enlarge the trackpad swipe seeking area on macOS.
- Customizable keyboard shortcuts for quick navigation.
- Environment driven configuration such as mute state, close actions, long‑press callbacks and foreground color.
- Built using pure SwiftUI with minimal dependencies.

## Installation

Add `PDVideoPlayer` to your project using Swift Package Manager. In Xcode choose **File \> Add Packages...** and enter `https://github.com/lynnswap/PDVideoPlayer` as the package URL. Alternatively, you can declare it in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/lynnswap/PDVideoPlayer", from: "0.1.x")
]
```

Then import `PDVideoPlayer` where needed.

## Basic Usage

Create a player from a `URL` or an existing `AVPlayer` and provide optional menus and content.

```swift
import PDVideoPlayer

struct ContentView: View {
    let videoURL: URL
    @State private var isMuted: Bool = false
    @State private var speed: PlaybackSpeed = .x1_0
    var body: some View {
        PDVideoPlayer(url: videoURL) { proxy in
            ZStack {
                proxy.player
                    .onTap { inside in
                        print("tap", inside)
                    }
#if os(iOS)
                    .skipRippleEffect()
                        // adds a ripple animation when double‑tap skipping
#endif
#if os(macOS)
                    .onPresentationSizeChange({ view, size in
                        // e.g. handle window resizing or other presentation-size changes
                    })
#endif
                    .ignoresSafeArea()
                VStack {
                    proxy.navigation
                    Spacer()
                    proxy.control
                        .knobSize(16)
                        .frame(maxWidth: 500,alignment: .center)
                }
            }
        }
        .videoPlayerMenu {
            Button("Sample 1") { print("Button 1") }
            Button("Sample 2") { print("Button 2") }
        }
        .isMuted($isMuted)
        .playbackSpeed($speed)
        .onLongPress { value in
            print("onLongPress", value)
        }
        .onClose { value in
            print("onClose", value)
        }
        .playerForegroundColor(Color.white)
    }
}
```

## Example

An example implementation is provided in
`Sources/PDVideoPlayer/Example/PDVideoPlayerSampleView.swift`.
This view showcases a basic player setup with custom controls.

## Modifiers

`PDVideoPlayer` provides modifiers for each view in the player hierarchy:

### `PDVideoPlayer`

- `isMuted(_:)` – Bind the mute state.
- `playbackSpeed(_:)` – Bind the playback speed.
- `onClose(_:)` – Handle closing the player.
- `onLongPress(_:)` – Respond to long‑press gestures.
- `playerForegroundColor(_:)` – Set tint color for controls.
- `windowDraggable(_:)` – Allow dragging the window. *(macOS)*

### Player View (`proxy.player`)

- `onTap(_:)` – Handle taps on the player.
- `onPresentationSizeChange(_:)` – Observe the presentation size.
- `scrollViewConfigurator(_:)` – Customize the underlying scroll view.
- `contextMenuProvider(_:)` – Provide a custom context menu. *(iOS)*
- `skipRippleEffect()` – Show a ripple animation when double‑tap skipping. *(iOS)*
- `playerViewConfigurator(_:)` – Configure the underlying `NSView`. *(macOS)*

### Control View (`proxy.control`)

- `knobSize(_:)` – Adjust the slider knob size.
- `trackpadSwipeOverlay()` – Expand the area for trackpad swipe seeking. *(macOS)*

### Content Container

- `videoPlayerKeyboardShortcuts(_:)` – Add keyboard shortcuts for playback.

## Apps Using

<p float="left">
    <a href="https://apps.apple.com/jp/app/tweetpd/id1671411031"><img src="https://i.imgur.com/AC6eGdx.png" height="65"></a>
</p>

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.
