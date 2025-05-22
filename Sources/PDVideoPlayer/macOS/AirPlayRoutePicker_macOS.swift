//
//  AirPlayRoutePicker.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/25.
//

import SwiftUI
import AVKit
#if os(macOS)
public struct AirPlayRoutePicker: NSViewRepresentable {
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor

    public func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.prioritizesVideoDevices = true
        picker.contentMode = .scaleAspectFit
        picker.activeTintColor = .systemBlue
        picker.tintColor = NSColor(foregroundColor.opacity(0.8))

        if let button = picker.subviews.compactMap({ $0 as? NSButton }).first {
            button.layer?.sublayers?.first?.isHidden = true

            let hosting = NSHostingView(rootView: AirPlayRouteLabelView())
            hosting.frame = button.bounds
            hosting.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(hosting)

            NSLayoutConstraint.activate([
                hosting.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                hosting.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                hosting.widthAnchor.constraint(equalTo: button.widthAnchor),
                hosting.heightAnchor.constraint(equalTo: button.heightAnchor)
            ])
        }

        return picker
    }

    public func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
    }
}
struct AirPlayRouteLabelView: View {
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    var body: some View {
        ZStack {
            Color.clear
            Image(systemName: "airplayvideo")
                .foregroundStyle(foregroundColor)
                .fontDesign(.rounded)
                .opacity(0.8)
        }
        .contentShape(Rectangle())
    }
}
#endif
