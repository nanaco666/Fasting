import Foundation

public enum FastingPreset: String, Codable, CaseIterable, Identifiable {
    case sixteen8 = "16:8"
    case eighteen6 = "18:6"
    case twenty4 = "20:4"
    case omad = "OMAD"
    case custom = "Custom"

    public var id: String { rawValue }

    public var fastingHours: Int {
        switch self {
        case .sixteen8: return 16
        case .eighteen6: return 18
        case .twenty4: return 20
        case .omad: return 23
        case .custom: return 16
        }
    }

    public var eatingWindow: Int {
        24 - fastingHours
    }

    public var displayName: String {
        switch self {
        case .sixteen8: return "16:8"
        case .eighteen6: return "18:6"
        case .twenty4: return "20:4"
        case .omad: return "OMAD (每日一餐)"
        case .custom: return "自定义"
        }
    }
}

public enum FastingStatus: String, Codable {
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"

    public var displayName: String {
        switch self {
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        }
    }
}
