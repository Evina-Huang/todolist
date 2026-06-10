import Foundation

struct TodayWidgetTask: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var reminderDate: Date?
    var isRoutineInstance: Bool
}

struct TodayWidgetSnapshot: Codable, Equatable {
    var date: Date
    var totalCount: Int
    var completedCount: Int
    var tasks: [TodayWidgetTask]

    static let placeholder = TodayWidgetSnapshot(
        date: Date(),
        totalCount: 3,
        completedCount: 1,
        tasks: [
            TodayWidgetTask(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
                title: "整理今天要做的事",
                reminderDate: nil,
                isRoutineInstance: false
            ),
            TodayWidgetTask(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
                title: "给例行事项设置提醒",
                reminderDate: Date().addingTimeInterval(60 * 60 * 3),
                isRoutineInstance: true
            )
        ]
    )

    static let empty = TodayWidgetSnapshot(
        date: Date(),
        totalCount: 0,
        completedCount: 0,
        tasks: []
    )

    var remainingCount: Int {
        max(totalCount - completedCount, 0)
    }

    var progress: Double {
        guard totalCount > 0 else { return 1 }
        return min(max(Double(completedCount) / Double(totalCount), 0), 1)
    }
}

enum TodayWidgetSnapshotStore {
    static let suiteName = "group.com.evina.quiettoday"

    private static let fileName = "today-widget-snapshot.json"

    static func load(fileManager: FileManager = .default) -> TodayWidgetSnapshot? {
        guard let url = snapshotURL(fileManager: fileManager),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(TodayWidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: TodayWidgetSnapshot, fileManager: FileManager = .default) {
        guard let url = snapshotURL(fileManager: fileManager),
              let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        try? data.write(to: url, options: [.atomic])
    }

    private static func snapshotURL(fileManager: FileManager) -> URL? {
        if let sharedURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName) {
            return sharedURL.appendingPathComponent(fileName)
        }

        guard let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let quietTodayURL = supportURL.appendingPathComponent("QuietToday", isDirectory: true)
        try? fileManager.createDirectory(at: quietTodayURL, withIntermediateDirectories: true)
        return quietTodayURL.appendingPathComponent(fileName)
    }
}
