import Foundation

extension Double {
    var mmSSString: String {
        guard self.isFinite && self >= 0 else { return "00:00" }
        let totalSec = Int(self)
        let minutes = totalSec / 60
        let seconds = totalSec % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
