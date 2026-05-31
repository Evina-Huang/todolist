import Foundation

enum ReminderOption: String, CaseIterable, Codable, Identifiable {
    case none
    case laterToday
    case tonight
    case tomorrowMorning
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "不提醒"
        case .laterToday:
            "今天晚点"
        case .tonight:
            "今晚"
        case .tomorrowMorning:
            "明早"
        case .custom:
            "自定义"
        }
    }
}

struct Reminder: Codable, Equatable {
    var date: Date

    var timeLabel: String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
