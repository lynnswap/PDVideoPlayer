//
//  MPVolumeView.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/25.
//
import SwiftUI
import AVKit
import MediaPlayer
#if os(macOS)
#else
struct AirPlayRoutePicker_MPVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: .zero)
        return volumeView
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
#endif
