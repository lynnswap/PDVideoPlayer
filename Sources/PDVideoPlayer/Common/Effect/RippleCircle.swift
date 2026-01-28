import SwiftUI

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
            let progress = min(currentTime / totalDuration, 1.0)
            let scaleProgress = progress
            let fadeProgress = max(
                0,
                (progress - (animationDuration / totalDuration))
                  * (totalDuration / fadeOutDuration)
            )
            let radius = maxRadius * CGFloat(scaleProgress)
            let opacity = 1 - fadeProgress
            if currentTime < totalDuration {
                Circle()
                    .fill(rippleColor)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: center.x, y: center.y)
                    .opacity(opacity)
            }
        }
    }
}
