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

enum RoutineReminderLeadTime: String, CaseIterable, Codable, Identifiable {
    case oneWeek
    case threeDays
    case oneDay
    case sameDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneWeek:
            "提前一周"
        case .threeDays:
            "提前 3 天"
        case .oneDay:
            "提前 1 天"
        case .sameDay:
            "当天"
        }
    }

    var daysBefore: Int {
        switch self {
        case .oneWeek:
            7
        case .threeDays:
            3
        case .oneDay:
            1
        case .sameDay:
            0
        }
    }
}

struct RoutineReminder: Identifiable, Codable, Equatable {
    var id: UUID
    var leadTime: RoutineReminderLeadTime
    var time: Date

    init(
        id: UUID = UUID(),
        leadTime: RoutineReminderLeadTime = .oneWeek,
        time: Date = Self.defaultTime
    ) {
        self.id = id
        self.leadTime = leadTime
        self.time = time
    }

    var label: String {
        "\(leadTime.title) \(time.formatted(date: .omitted, time: .shortened))"
    }

    static var defaultTime: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

struct Routine: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var frequency: RoutineFrequency
    var weekday: Int
    var monthDay: Int
    var reminders: [RoutineReminder]
    var createdAt: Date
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        title: String,
        frequency: RoutineFrequency = .monthly,
        weekday: Int = Calendar.current.component(.weekday, from: Date()),
        monthDay: Int = 25,
        reminders: [RoutineReminder] = [],
        createdAt: Date = Date(),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.frequency = frequency
        self.weekday = weekday
        self.monthDay = monthDay
        self.reminders = reminders
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

    func reminderDate(for reminder: RoutineReminder, on date: Date, calendar: Calendar = .current) -> Date? {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminder.time)
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        guard let occurrenceDate = calendar.date(from: components) else { return nil }
        return calendar.date(
            byAdding: .day,
            value: -reminderOffsetDays(for: reminder),
            to: occurrenceDate
        ) ?? occurrenceDate
    }

    func reminder(on date: Date, calendar: Calendar = .current) -> Reminder? {
        guard let firstReminder = reminders.first,
              let date = reminderDate(for: firstReminder, on: date, calendar: calendar) else {
            return nil
        }
        return Reminder(date: date)
    }

    func taskReminder(on date: Date, calendar: Calendar = .current) -> Reminder? {
        guard frequency != .monthly else { return nil }
        return reminder(on: date, calendar: calendar)
    }

    func upcomingReminderDates(
        after date: Date = Date(),
        limit: Int,
        calendar: Calendar = .current
    ) -> [Date] {
        guard !reminders.isEmpty, isEnabled, limit > 0 else { return [] }

        var reminderDates: [Date] = []
        var occurrenceDate = calendar.startOfDay(for: date)
        var checkedDays = 0

        while reminderDates.count < limit && checkedDays < 370 {
            if occurs(on: occurrenceDate, calendar: calendar) {
                let dates = reminders.compactMap { reminder in
                    reminderDate(for: reminder, on: occurrenceDate, calendar: calendar)
                }
                reminderDates.append(contentsOf: dates.filter { $0 > date })
                reminderDates.sort()
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: occurrenceDate) else {
                break
            }
            occurrenceDate = nextDate
            checkedDays += 1
        }

        return Array(reminderDates.prefix(limit))
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
        guard !reminders.isEmpty else { return nil }

        if reminders.count == 1, let firstReminder = reminders.first {
            if frequency == .monthly {
                return firstReminder.label
            }
            return firstReminder.time.formatted(date: .omitted, time: .shortened)
        }

        return "\(reminders.count) 次提醒"
    }

    private func reminderOffsetDays(for reminder: RoutineReminder) -> Int {
        frequency == .monthly ? reminder.leadTime.daysBefore : 0
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case frequency
        case weekday
        case monthDay
        case reminderTime
        case reminderLeadTime
        case reminders
        case createdAt
        case isEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        frequency = try container.decode(RoutineFrequency.self, forKey: .frequency)
        weekday = try container.decode(Int.self, forKey: .weekday)
        monthDay = try container.decode(Int.self, forKey: .monthDay)
        if let decodedReminders = try container.decodeIfPresent([RoutineReminder].self, forKey: .reminders) {
            reminders = decodedReminders
        } else if let reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime) {
            let leadTime = try container.decodeIfPresent(RoutineReminderLeadTime.self, forKey: .reminderLeadTime) ?? .oneWeek
            reminders = [RoutineReminder(leadTime: leadTime, time: reminderTime)]
        } else {
            reminders = []
        }
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(weekday, forKey: .weekday)
        try container.encode(monthDay, forKey: .monthDay)
        try container.encode(reminders, forKey: .reminders)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isEnabled, forKey: .isEnabled)
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
