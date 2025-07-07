//
//  ContentView.swift
//  PDVideoPlayerDemo
//
//  Created by lynnswap on 2025/07/07.
//

import SwiftUI
import PDVideoPlayer

struct ContentView: View {
    var body: some View {
        PDVideoPlayerSampleView(sampleURL: URL(fileURLWithPath: "/Users/kn/Downloads/ScreenRecording_04-20-2025 17-25-50_1.mov"))
    }
}

#Preview {
    ContentView()
}
