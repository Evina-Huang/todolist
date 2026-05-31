import SwiftUI

@main
struct QuietTodayApp: App {
    @StateObject private var store = TaskStore()
    private let notifications = NotificationScheduler()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environment(\.notificationScheduler, notifications)
                .task {
                    await store.refreshToday()
                }
        }
    }
}
