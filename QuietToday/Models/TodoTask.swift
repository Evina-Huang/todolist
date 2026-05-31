import Foundation

enum TaskSource: Codable, Equatable {
    case manual
    case routine(routineID: UUID, occurrenceKey: String)
}

struct TodoTask: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var createdAt: Date
    var dueDate: Date
    var completedAt: Date?
    var skippedAt: Date?
    var reminder: Reminder?
    var source: TaskSource

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        dueDate: Date = Date(),
        completedAt: Date? = nil,
        skippedAt: Date? = nil,
        reminder: Reminder? = nil,
        source: TaskSource = .manual
    ) {
        self.id = id
        self.title = TodoTask.sanitizedTitle(title)
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.completedAt = completedAt
        self.skippedAt = skippedAt
        self.reminder = reminder
        self.source = source
    }

    static func sanitizedTitle(_ title: String) -> String {
        title
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    var isSkipped: Bool {
        skippedAt != nil
    }

    var isRoutineInstance: Bool {
        if case .routine = source {
            return true
        }
        return false
    }
}
