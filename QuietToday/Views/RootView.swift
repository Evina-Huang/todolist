import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("待办", systemImage: "checklist")
                }
                .tag(0)

            RoutineListView()
                .tabItem {
                    Label("日程", systemImage: "repeat")
                }
                .tag(1)
        }
        .tint(QuietColor.sage)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await store.refreshToday()
            }
        }
    }
}
