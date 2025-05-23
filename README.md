# PDVideoPlayer

**PDVideoPlayer** is a Swift Package that provides a customizable video player component for SwiftUI on both iOS and macOS. It wraps `AVPlayer` inside a SwiftUI view and exposes convenient APIs for common playback controls.

## Features

- Universal support for **iOS** and **macOS** using the same code base.
- Picture-in-Picture on iOS via `PiPManager`.
- AirPlay route picker for streaming to external displays.
- Gesture handling including double-tap skip with ripple effects, long press speed changes, and optional pan gestures for rotation or vertical seeking.
- Customizable keyboard shortcuts for quick navigation.
- Environment driven configuration such as mute state, close actions, long‑press callbacks and foreground color.
- Built using pure SwiftUI with minimal dependencies.

## Installation

Add `PDVideoPlayer` to your project using Swift Package Manager. In Xcode choose **File \> Add Packages...** and enter `https://github.com/lynnswap/PDVideoPlayer` as the package URL. Alternatively, you can declare it in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/lynnswap/PDVideoPlayer", from: "0.0.1")
]
```

Then import `PDVideoPlayer` where needed.

## Basic Usage

Create a player from a `URL` or an existing `AVPlayer` and provide optional menus and content.

```swift
import PDVideoPlayer

struct ContentView: View {
    let videoURL: URL
    var body: some View {
        PDVideoPlayer(url: videoURL, menu: {
            Button("Sample 1") { print("Button 1") }
            Button("Sample 2") { print("Button 2") }
        }) { proxy in
            ZStack {
                proxy.player
                    .tapAction { inside in
                        print("tap", inside)
                    }
                VStack {
                    proxy.navigation
                    Spacer()
                    proxy.control
                }
            }
        }
        .isMuted(.constant(false))
        .playerForegroundColor(.white)
    }
}
```

## Modifiers

`PDVideoPlayer` provides several modifiers to customize behavior:

- `isMuted(_:)` – Bind the mute state.
- `closeAction(_:)` – Handle closing the player.
- `longpressAction(_:)` – Respond to long‑press gestures.
- `playerForegroundColor(_:)` – Set tint color for controls.
- `panGesture(_:)` – Choose the pan gesture type on iOS.
- `windowDraggable(_:)` – Allow dragging the macOS window by the player view.

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.
