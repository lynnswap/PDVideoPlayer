#if os(iOS) || os(macOS)
import Foundation

/// Supported playback speeds for the video player.
public enum PlaybackSpeed: String, CaseIterable, Identifiable {
    case x0_5
    case x1_0
    case x1_25
    case x1_5
    case x2_0

    public var id: String { rawValue }

    /// Numeric rate value associated with the speed.
    public var value: Float {
        switch self {
        case .x0_5: return 0.5
        case .x1_0: return 1.0
        case .x1_25: return 1.25
        case .x1_5: return 1.5
        case .x2_0: return 2.0
        }
    }

    /// Display string used by menu views.
    public var displayName: String {
        switch self {
        case .x0_5: return "0.5x"
        case .x1_0: return "1.0x"
        case .x1_25: return "1.25x"
        case .x1_5: return "1.5x"
        case .x2_0: return "2.0x"
        }
    }
}
#endif
