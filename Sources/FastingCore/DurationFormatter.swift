import Foundation

public enum DurationFormatter {
    public static func format(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    public static func formatShort(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    public static func progress(
        current: TimeInterval,
        target: TimeInterval
    ) -> Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
}
