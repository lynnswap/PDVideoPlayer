//
//  RippleCircle.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/04/14.
//
import SwiftUI
/// 実際に波紋を描画する円
//struct RippleCircle: View {
//    var rippleColor: Color
//    var center: CGPoint
//    var maxRadius: CGFloat
//    var animationDuration: Double
//    var fadeOutDuration: Double
//    var startDate: Date
//    
//    @State private var currentTime: TimeInterval = 0
//    
//    var body: some View {
//        let totalDuration = animationDuration + fadeOutDuration
//        let progress = min(currentTime / totalDuration, 1.0)
//        
//        // 拡大進捗
//        let scaleProgress = progress
//        // フェードアウト進捗
//        let fadeProgress = max(
//            0,
//            (progress - (animationDuration / totalDuration))
//            * (totalDuration / fadeOutDuration)
//        )
//        
//        let radius = maxRadius * CGFloat(scaleProgress)
//        let opacity = 1 - fadeProgress
//        
//        return Circle()
//            .fill(rippleColor)
//            .frame(width: radius * 2, height: radius * 2)
//            .position(x: center.x, y: center.y)
//            .opacity(opacity)
//            .onAppear {
//                // CADisplayLink でアニメ時間を計測
//                let displayLink = CADisplayLink(
//                    target: DisplayLinkProxy { link in
//                        let now = Date()
//                        currentTime = now.timeIntervalSince(startDate)
//                        if currentTime >= totalDuration {
//                            link.invalidate()
//                        }
//                    },
//                    selector: #selector(DisplayLinkProxy.update)
//                )
//                displayLink.add(to: .main, forMode: .common)
//            }
//    }
//}
//private class DisplayLinkProxy {
//    let block: (CADisplayLink) -> Void
//    init(_ block: @escaping (CADisplayLink) -> Void) { self.block = block }
//    @objc func update(_ displayLink: CADisplayLink) { block(displayLink) }
//}
struct RippleCircle: View {
    var rippleColor: Color
    var center: CGPoint
    var maxRadius: CGFloat
    var animationDuration: Double
    var fadeOutDuration: Double
    var startDate: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 60.0)) { context in
            let now = context.date
            let currentTime = now.timeIntervalSince(startDate)

            let totalDuration = animationDuration + fadeOutDuration
            // 全体の進捗（0.0 ~ 1.0）を計算
            let progress = min(currentTime / totalDuration, 1.0)

            // 拡大の進捗
            let scaleProgress = progress

            // フェードアウトの進捗
            let fadeProgress = max(
                0,
                (progress - (animationDuration / totalDuration))
                  * (totalDuration / fadeOutDuration)
            )

            // 円の半径と不透明度を進捗に応じて計算
            let radius = maxRadius * CGFloat(scaleProgress)
            let opacity = 1 - fadeProgress

            // まだアニメーションが継続中なら描画
            if currentTime < totalDuration {
                Circle()
                    .fill(rippleColor)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: center.x, y: center.y)
                    .opacity(opacity)
            }
            // totalDurationを超えたら描画しない（→ Store 側で削除予定）
        }
    }
}
