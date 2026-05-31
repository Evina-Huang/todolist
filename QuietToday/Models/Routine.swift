import Foundation

enum RoutineFrequency: String, CaseIterable, Codable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            "每天"
        case .weekly:
            "每周"
        case .monthly:
            "每月"
        }
    }
}

struct Routine: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var frequency: RoutineFrequency
    var weekday: Int
    var monthDay: Int
    var reminderTime: Date?
    var createdAt: Date
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        title: String,
        frequency: RoutineFrequency = .weekly,
        weekday: Int = Calendar.current.component(.weekday, from: Date()),
        monthDay: Int = Calendar.current.component(.day, from: Date()),
        reminderTime: Date? = nil,
        createdAt: Date = Date(),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.frequency = frequency
        self.weekday = weekday
        self.monthDay = monthDay
        self.reminderTime = reminderTime
        self.createdAt = createdAt
        self.isEnabled = isEnabled
    }

    func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return false }

        switch frequency {
        case .daily:
            return true
        case .weekly:
            return calendar.component(.weekday, from: date) == weekday
        case .monthly:
            return calendar.component(.day, from: date) == monthDay
        }
    }

    func occurrenceKey(for date: Date, calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: date)
        return Self.occurrenceFormatter.string(from: start)
    }

    func reminder(on date: Date, calendar: Calendar = .current) -> Reminder? {
        guard let reminderTime else { return nil }

        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        guard let date = calendar.date(from: components) else { return nil }
        return Reminder(date: date)
    }

    var cadenceLabel: String {
        switch frequency {
        case .daily:
            "每天"
        case .weekly:
            "每周\(Self.weekdaySymbols[weekday - 1])"
        case .monthly:
            "每月 \(monthDay) 日"
        }
    }

    var reminderLabel: String? {
        reminderTime?.formatted(date: .omitted, time: .shortened)
    }

    private static let occurrenceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let weekdaySymbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
}
