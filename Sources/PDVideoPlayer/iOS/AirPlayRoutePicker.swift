//
//  AirPlayRoutePicker.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/25.
//

import SwiftUI
import AVKit
#if os(macOS) || os(visionOS)
#else
public struct AirPlayRoutePicker: UIViewRepresentable {
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor

    public func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.prioritizesVideoDevices = true
        picker.contentMode = .scaleAspectFit
        picker.activeTintColor = .systemBlue
        picker.tintColor = UIColor(foregroundColor.opacity(0.8))

        if let button = picker.subviews.compactMap({ $0 as? UIButton }).first {
            button.layer.sublayers?.first?.isHidden = true

            let hosting = UIHostingController(rootView: AirPlayRouteLabelView())
            hosting.view.backgroundColor = .clear

            button.addSubview(hosting.view)

            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hosting.view.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                hosting.view.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                hosting.view.widthAnchor.constraint(equalTo: button.widthAnchor),
                hosting.view.heightAnchor.constraint(equalTo: button.heightAnchor)
            ])
        }

        return picker
    }

    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
    }
}
struct AirPlayRouteLabelView:View{
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    var body:some View{
        ZStack{
            Color.clear
            Image(systemName:"airplayvideo")
                .foregroundStyle(foregroundColor)
                .fontDesign(.rounded)
                .opacity(0.8)
        }
        .contentShape(Rectangle())
    }
}
#endif
