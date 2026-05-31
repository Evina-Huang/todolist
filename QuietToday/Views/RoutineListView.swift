import SwiftUI

struct RoutineListView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.notificationScheduler) private var notifications
    @State private var editingRoutine: Routine?
    @State private var isAddingRoutine = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    routineList
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 34)
            }
            .quietScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editingRoutine) { routine in
                RoutineEditorView(routine: routine)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isAddingRoutine) {
                RoutineEditorView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Spacer()

            Button {
                isAddingRoutine = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(QuietColor.sage)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("新增日程")
        }
    }

    @ViewBuilder
    private var routineList: some View {
        if store.upcomingRoutines.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("还没有日程")
                    .font(.title3.weight(.medium))

                Text("点右上角新增一个会重复出现的事项。")
                    .font(.body)
                    .foregroundStyle(QuietColor.secondaryInk)
            }
            .padding(.top, 24)
        } else {
            VStack(spacing: 12) {
                ForEach(store.upcomingRoutines) { routine in
                    RoutineRow(routine: routine) {
                        editingRoutine = routine
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.deleteRoutine(routine)
                            Task {
                                await notifications.rescheduleAll(tasks: store.tasks, routines: store.routines)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}
