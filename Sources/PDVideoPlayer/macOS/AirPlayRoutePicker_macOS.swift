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
    public var iconSize: CGFloat
    public init(
        iconSize:CGFloat = 24
    ) {
        self.iconSize = iconSize
    }
    public func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.isRoutePickerButtonBordered = false
        
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.widthAnchor .constraint(equalToConstant: self.iconSize),
            picker.heightAnchor.constraint(equalToConstant: self.iconSize)
        ])

        if let button = picker.subviews.compactMap({ $0 as? NSButton }).first {
            button.layer?.sublayers?.first?.isHidden = true

            let host = NSHostingView(rootView: AirPlayRouteLabelView())
            host.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(host)
            NSLayoutConstraint.activate([
                host.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                host.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                host.widthAnchor .constraint(equalTo: button.widthAnchor),
                host.heightAnchor.constraint(equalTo: button.heightAnchor)
            ])
        }
        return picker
    }

    public func updateNSView(_ picker: AVRoutePickerView, context: Context) {
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
