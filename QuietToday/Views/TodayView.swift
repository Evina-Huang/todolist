import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.notificationScheduler) private var notifications
    @FocusState private var isInputFocused: Bool
    @State private var draft = ""
    @State private var reminderTask: TodoTask?
    @State private var editingTaskID: TodoTask.ID?

    private var tasks: [TodoTask] {
        store.todayTasks
    }

    private var sanitizedDraft: String {
        TodoTask.sanitizedTitle(draft)
    }

    var body: some View {
        NavigationStack {
            List {
                header
                    .padding(.top, 24)
                    .quietListRow()

                composer
                    .padding(.top, 28)
                    .quietListRow()

                taskSpacing

                taskList

                Color.clear
                    .frame(height: 34)
                    .quietListRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .quietScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("收起") {
                        isInputFocused = false
                    }
                    .fontWeight(.medium)
                }
            }
            .sheet(item: $reminderTask) { task in
                TaskReminderView(task: task)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .task {
                await store.refreshToday()
            }
        }
    }

    private var header: some View {
        Text(QuietDateFormatter.header.string(from: Date()))
            .font(.title3.weight(.medium))
            .foregroundStyle(QuietColor.secondaryInk)
    }

    private var composer: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(QuietColor.sage)

            TextField("添加待办", text: $draft)
                .font(.system(size: 19, weight: .regular))
                .lineLimit(1)
                .submitLabel(.done)
                .focused($isInputFocused)
                .onSubmit(addDraft)
                .onChange(of: draft) { _, newValue in
                    guard newValue.rangeOfCharacter(from: .newlines) != nil else { return }
                    draft = TodoTask.sanitizedTitle(newValue)
                }

            Button(action: addDraft) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(sanitizedDraft.isEmpty ? QuietColor.mist : QuietColor.sage)
            }
            .buttonStyle(.plain)
            .disabled(sanitizedDraft.isEmpty)
            .accessibilityLabel("添加待办")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(QuietColor.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(QuietColor.line.opacity(0.72), lineWidth: 1)
        }
    }

    private var taskSpacing: some View {
        Color.clear
            .frame(height: tasks.isEmpty ? 0 : 28)
            .quietListRow()
    }

    @ViewBuilder
    private var taskList: some View {
        if tasks.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("现在很清静")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(QuietColor.ink)

                Text("有事时写下，没事时留白。")
                    .font(.body)
                    .foregroundStyle(QuietColor.secondaryInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 28)
            .quietListRow()
        } else {
            ForEach(tasks) { task in
                taskRow(for: task)
            }
        }
    }

    private func taskRow(for task: TodoTask) -> some View {
        TaskRow(
            task: task,
            editingTaskID: $editingTaskID,
            toggleCompletion: {
                store.toggleCompletion(for: task)
                if !task.isCompleted {
                    notifications.cancel(task: task)
                }
            },
            saveTitle: { title in
                store.updateTaskTitle(title, for: task)
            },
            pinTask: nil
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(QuietColor.background)
        .overlay(alignment: .bottom) {
            if task.id != tasks.last?.id {
                Divider()
                    .padding(.leading, 40)
                    .overlay(QuietColor.line.opacity(0.56))
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if task.isRoutineInstance {
                Button {
                    store.skipRoutineTask(task)
                    notifications.cancel(task: task)
                } label: {
                    Label("今天跳过", systemImage: "forward.fill")
                }
                .tint(.orange)
            } else {
                Button(role: .destructive) {
                    deleteTask(task)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                reminderTask = task
            } label: {
                Label(task.reminder == nil ? "提醒" : "改提醒", systemImage: "bell")
            }
            .tint(QuietColor.sage)
        }
        .quietListRow()
    }

    private func addDraft() {
        let title = TodoTask.sanitizedTitle(draft)
        guard !title.isEmpty else { return }

        store.addTask(title: title)
        draft = ""
        isInputFocused = true
    }

    private func deleteTask(_ task: TodoTask) {
        store.deleteTask(task)
        notifications.cancel(task: task)
    }
}

private extension View {
    func quietListRow() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
            .listRowSeparator(.hidden)
            .listRowBackground(QuietColor.background)
    }
}
