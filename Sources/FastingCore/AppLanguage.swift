import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}
