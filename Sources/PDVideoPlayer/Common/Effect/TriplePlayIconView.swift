//
//  TriplePlayIconView.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/04/14.
//
#if canImport(UIKit)
import SwiftUI
struct TriplePlayIconView: View {
    var model:PDPlayerModel
    var item:RippleData
    let totalRippleDuration: Double

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
            let elapsed = context.date.timeIntervalSince(item.startDate)
            let fraction = max(0, min(elapsed / totalRippleDuration, 1))
            let (icon1Opacity, icon2Opacity, icon3Opacity) = opacities(for: fraction)
            HStack {
                Image(systemName: "play.fill").opacity(icon1Opacity)
                Image(systemName: "play.fill").opacity(icon2Opacity)
                Image(systemName: "play.fill").opacity(icon3Opacity)
            }
        }
    }
    func opacities(for fraction: Double) -> (Double, Double, Double) {
        if model.doubleTapCount >= 2{
            switch fraction {
            case 0..<0.25: (1, 1, 1)
            case 0.25..<0.6: (1, 1, 1)
            case 0.6..<0.85: (0, 1, 1)
            default: (0, 0, 1)
            }
        }else{
            switch fraction {
            case 0..<0.25: (1, 0, 0)
            case 0.25..<0.5: (1, 1, 0)
            case 0.5..<0.75: (0, 1, 1)
            default: (0, 0, 1)
            }
        }
    }
}
#endif
