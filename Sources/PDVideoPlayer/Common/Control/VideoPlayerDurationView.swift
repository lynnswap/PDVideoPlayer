//
//  VideoPlayerDurationView.swift
//  PDVideoPlayer
//
//  Created by lynnswap on 2025/07/19.
//

import SwiftUI

struct VideoPlayerDurationView: View {
    var model:PDPlayerModel
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    var body:some View{
        Text("\(formatTime(model.currentTime)) / \(formatTime(model.duration))")
            .monospaced()
            .font(.caption)
            .foregroundStyle(foregroundColor)
            .opacity(0.8)
    }
    // MARK: - 時刻表示フォーマッタ
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && time >= 0 else { return "00:00" }
        let totalSec = Int(time)
        let minutes = totalSec / 60
        let seconds = totalSec % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
