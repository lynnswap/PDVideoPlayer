import SwiftUI
import Foundation

enum TapRegion {
    case left, middle, right
}

struct RippleData: Identifiable, Equatable {
    let id = UUID()
    let center: CGPoint
    let region: TapRegion
    let startDate: Date
    let skipDuration: Int
}

/// Stores and manages ripple state for tap feedback.
@MainActor
@Observable public class RippleEffectStore {
    private let maxRippleCount = 5
    
    var ripples: [RippleData] = []
    
    var globalEndTime: Date?

    var latestItem: RippleData?

    public var rippleColor: Color = .white.opacity(0.22)
    public var animationDuration: Double = 0.6
    public var fadeOutDuration: Double = 0.3
    
    var viewSize: CGSize = .zero

    private var removeAllTask: Task<Void, any Error>?

    func addRipple(at location: CGPoint, duration: Int) {
        let region = getTapRegion(for: location, in: viewSize)
        guard region != .middle else { return }

        let ripple = RippleData(
            center: location,
            region: region,
            startDate: Date(),
            skipDuration: duration
        )

        
        ripples.append(ripple)
        self.latestItem = ripple
        
        let totalDuration = animationDuration + fadeOutDuration
        globalEndTime = Date().addingTimeInterval(totalDuration)

        removeAllTask?.cancel()
        removeAllTask = Task {
            try await Task.sleep(for: .seconds(totalDuration))
            guard !Task.isCancelled else { return }
            self.clearAllRipples()
        }
    }

    func clearAllRipples() {
        ripples.removeAll()
        latestItem = nil
        globalEndTime = nil
    }

    private func getTapRegion(for location: CGPoint, in size: CGSize) -> TapRegion {
        guard size.width > 0 else { return .middle }
        let ratio = location.x / size.width
        if ratio < 0.4 {
            return .left
        } else if ratio > 0.6 {
            return .right
        } else {
            return .middle
        }
    }

    isolated deinit {
        removeAllTask?.cancel()
    }
}
