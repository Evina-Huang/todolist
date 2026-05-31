import Foundation

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TodoTask] = []
    @Published private(set) var routines: [Routine] = []

    private let calendar: Calendar
    private let tasksURL: URL
    private let routinesURL: URL

    init(
        calendar: Calendar = .current,
        fileManager: FileManager = .default
    ) {
        self.calendar = calendar
        let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QuietToday", isDirectory: true)
        try? fileManager.createDirectory(at: supportURL, withIntermediateDirectories: true)
        tasksURL = supportURL.appendingPathComponent("tasks.json")
        routinesURL = supportURL.appendingPathComponent("routines.json")
        load()
    }

    var todayTasks: [TodoTask] {
        let today = calendar.startOfDay(for: Date())
        return tasks
            .filter { calendar.isDate($0.dueDate, inSameDayAs: today) && !$0.isSkipped }
            .sorted { first, second in
                switch (first.reminder?.date, second.reminder?.date) {
                case let (.some(lhs), .some(rhs)):
                    if lhs != rhs { return lhs < rhs }
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    break
                }

                if first.isCompleted != second.isCompleted {
                    return !first.isCompleted
                }

                return first.createdAt < second.createdAt
            }
    }

    var upcomingRoutines: [Routine] {
        routines
            .filter(\.isEnabled)
            .sorted { $0.createdAt < $1.createdAt }
    }

    func refreshToday() async {
        materializeRoutines(for: Date())
    }

    func addTask(title: String) {
        let sanitizedTitle = TodoTask.sanitizedTitle(title)
        guard !sanitizedTitle.isEmpty else { return }

        tasks.append(TodoTask(title: sanitizedTitle, dueDate: Date()))
        saveTasks()
    }

    func updateTask(_ task: TodoTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        saveTasks()
    }

    func toggleCompletion(for task: TodoTask) {
        guard var updated = tasks.first(where: { $0.id == task.id }) else { return }
        updated.completedAt = updated.completedAt == nil ? Date() : nil
        updateTask(updated)
    }

    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func skipRoutineTask(_ task: TodoTask) {
        guard var updated = tasks.first(where: { $0.id == task.id }) else { return }
        updated.skippedAt = Date()
        updateTask(updated)
    }

    func setReminder(_ reminder: Reminder?, for task: TodoTask) {
        guard var updated = tasks.first(where: { $0.id == task.id }) else { return }
        updated.reminder = reminder
        updateTask(updated)
    }

    func updateTaskDetails(title: String, reminder: Reminder?, for task: TodoTask) {
        let sanitizedTitle = TodoTask.sanitizedTitle(title)
        guard !sanitizedTitle.isEmpty else { return }
        guard var updated = tasks.first(where: { $0.id == task.id }) else { return }

        updated.title = sanitizedTitle
        updated.reminder = reminder
        updateTask(updated)
    }

    func updateTaskTitle(_ title: String, for task: TodoTask) {
        let sanitizedTitle = TodoTask.sanitizedTitle(title)
        guard !sanitizedTitle.isEmpty else { return }
        guard var updated = tasks.first(where: { $0.id == task.id }) else { return }

        updated.title = sanitizedTitle
        updateTask(updated)
    }

    @discardableResult
    func addRoutine(
        title: String,
        frequency: RoutineFrequency,
        weekday: Int,
        monthDay: Int,
        reminderTime: Date?
    ) -> Routine? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        let routine = Routine(
            title: trimmedTitle,
            frequency: frequency,
            weekday: max(1, min(7, weekday)),
            monthDay: max(1, min(31, monthDay)),
            reminderTime: reminderTime
        )
        routines.append(routine)
        saveRoutines()
        materializeRoutines(for: Date())
        return routine
    }

    @discardableResult
    func addRoutine(
        from task: TodoTask,
        title: String,
        frequency: RoutineFrequency,
        weekday: Int,
        monthDay: Int,
        reminderTime: Date?
    ) -> Routine? {
        let trimmedTitle = TodoTask.sanitizedTitle(title)
        guard !trimmedTitle.isEmpty else { return nil }
        guard let taskIndex = tasks.firstIndex(where: { $0.id == task.id }) else { return nil }
        guard !tasks[taskIndex].isRoutineInstance else { return nil }

        let routine = Routine(
            title: trimmedTitle,
            frequency: frequency,
            weekday: max(1, min(7, weekday)),
            monthDay: max(1, min(31, monthDay)),
            reminderTime: reminderTime
        )
        routines.append(routine)

        let dueDate = tasks[taskIndex].dueDate
        tasks[taskIndex].title = trimmedTitle
        tasks[taskIndex].reminder = routine.reminder(on: dueDate, calendar: calendar)

        if routine.occurs(on: dueDate, calendar: calendar) {
            tasks[taskIndex].source = .routine(
                routineID: routine.id,
                occurrenceKey: routine.occurrenceKey(for: dueDate, calendar: calendar)
            )
        }

        saveRoutines()
        saveTasks()
        materializeRoutines(for: Date())
        return routine
    }

    func updateRoutine(_ routine: Routine) {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        routines[index] = routine
        syncTodayInstance(for: routine)
        saveRoutines()
        materializeRoutines(for: Date())
    }

    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        tasks.removeAll { task in
            if case let .routine(routineID, _) = task.source {
                return routineID == routine.id && !task.isCompleted
            }
            return false
        }
        saveRoutines()
        saveTasks()
    }

    private func materializeRoutines(for date: Date) {
        let today = calendar.startOfDay(for: date)
        var didChange = false

        for routine in routines where routine.occurs(on: today, calendar: calendar) {
            let key = routine.occurrenceKey(for: today, calendar: calendar)
            let exists = tasks.contains { task in
                if case let .routine(routineID, occurrenceKey) = task.source {
                    return routineID == routine.id && occurrenceKey == key
                }
                return false
            }

            guard !exists else { continue }

            tasks.append(
                TodoTask(
                    title: routine.title,
                    dueDate: today,
                    reminder: routine.reminder(on: today, calendar: calendar),
                    source: .routine(routineID: routine.id, occurrenceKey: key)
                )
            )
            didChange = true
        }

        if didChange {
            saveTasks()
        }
    }

    private func syncTodayInstance(for routine: Routine) {
        let today = calendar.startOfDay(for: Date())
        var didChange = false

        tasks.removeAll { task in
            guard case let .routine(routineID, _) = task.source, routineID == routine.id else {
                return false
            }

            let isToday = calendar.isDate(task.dueDate, inSameDayAs: today)
            let shouldRemove = isToday && !task.isCompleted && !routine.occurs(on: today, calendar: calendar)
            if shouldRemove {
                didChange = true
            }
            return shouldRemove
        }

        guard routine.occurs(on: today, calendar: calendar) else {
            if didChange {
                saveTasks()
            }
            return
        }

        let key = routine.occurrenceKey(for: today, calendar: calendar)
        guard let index = tasks.firstIndex(where: { task in
            if case let .routine(routineID, occurrenceKey) = task.source {
                return routineID == routine.id && occurrenceKey == key
            }
            return false
        }) else {
            if didChange {
                saveTasks()
            }
            return
        }

        tasks[index].title = routine.title
        tasks[index].reminder = routine.reminder(on: today, calendar: calendar)
        saveTasks()
    }

    private func load() {
        tasks = decode([TodoTask].self, from: tasksURL) ?? []
        routines = decode([Routine].self, from: routinesURL) ?? []
        materializeRoutines(for: Date())
    }

    private func saveTasks() {
        encode(tasks, to: tasksURL)
    }

    private func saveRoutines() {
        encode(routines, to: routinesURL)
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.quietToday.decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder.quietToday.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

}

private extension JSONEncoder {
    static var quietToday: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var quietToday: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
