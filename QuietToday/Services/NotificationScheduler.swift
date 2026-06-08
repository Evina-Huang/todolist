import SwiftUI
import UserNotifications

struct NotificationSchedulerKey: EnvironmentKey {
    static let defaultValue = NotificationScheduler()
}

extension EnvironmentValues {
    var notificationScheduler: NotificationScheduler {
        get { self[NotificationSchedulerKey.self] }
        set { self[NotificationSchedulerKey.self] = newValue }
    }
}

final class NotificationScheduler {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }

        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            // Quietly continue; the app remains usable without reminders.
        }
    }

    func rescheduleAll(tasks: [TodoTask], routines: [Routine]) async {
        center.removeAllPendingNotificationRequests()

        for task in tasks where !task.isCompleted && !task.isSkipped {
            await schedule(task: task)
        }

        for routine in routines where routine.isEnabled {
            await schedule(routine: routine)
        }
    }

    func schedule(task: TodoTask) async {
        guard let reminder = task.reminder, reminder.date > Date() else {
            center.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
            return
        }

        await requestAuthorizationIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = "待办"
        content.body = task.title
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            // A rejected notification should not block task editing.
        }
    }

    func cancel(task: TodoTask) {
        center.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }

    private func schedule(routine: Routine) async {
        let reminderDates = routine.upcomingReminderDates(limit: 12)
        guard !reminderDates.isEmpty else { return }

        await requestAuthorizationIfNeeded()

        for (index, reminderDate) in reminderDates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "日程"
            content.body = routine.title
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "routine-\(routine.id.uuidString)-\(index)",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                // A rejected notification should not block routine editing.
            }
        }
    }
}
