import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationScheduler) private var notifications

    let task: TodoTask
    @State private var title = ""
    @State private var selectedOption: ReminderOption = .none
    @State private var customDate = Date()

    private var canSave: Bool {
        !TodoTask.sanitizedTitle(title).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("待办内容", text: $title, axis: .vertical)
                        .font(.title3.weight(.semibold))
                        .lineLimit(nil)
                        .foregroundStyle(QuietColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .onChange(of: title) { _, newValue in
                            guard newValue.rangeOfCharacter(from: .newlines) != nil else { return }
                            title = TodoTask.sanitizedTitle(newValue)
                        }

                    if task.isRoutineInstance {
                        Text("这里只修改今天这一次。")
                            .font(.footnote)
                            .foregroundStyle(QuietColor.secondaryInk)
                    }
                }

                Section("提醒") {
                    Picker("提醒", selection: $selectedOption) {
                        ForEach(ReminderOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)

                    if selectedOption == .custom {
                        DatePicker("日期和时间", selection: $customDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    } else if let previewDate = reminderForSelection() {
                        HStack {
                            Text("将提醒")
                            Spacer()
                            Text(QuietDateFormatter.reminderPreview.string(from: previewDate.date))
                                .foregroundStyle(QuietColor.secondaryInk)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(QuietColor.background)
            .navigationTitle("待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .onAppear {
                title = task.title
                if let reminder = task.reminder {
                    selectedOption = .custom
                    customDate = reminder.date
                } else {
                    selectedOption = .none
                    customDate = Date().addingTimeInterval(60 * 60)
                }
            }
        }
        .tint(QuietColor.sage)
    }

    private func save() {
        let reminder = reminderForSelection()
        store.updateTaskDetails(title: title, reminder: reminder, for: task)

        if let updatedTask = store.tasks.first(where: { $0.id == task.id }) {
            Task {
                await notifications.schedule(task: updatedTask)
            }
        }

        dismiss()
    }

    private func reminderForSelection() -> Reminder? {
        let now = Date()
        let calendar = Calendar.current

        switch selectedOption {
        case .none:
            return nil
        case .laterToday:
            return Reminder(date: now.addingTimeInterval(2 * 60 * 60))
        case .tonight:
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 20
            components.minute = 0
            let date = calendar.date(from: components) ?? now.addingTimeInterval(2 * 60 * 60)
            return Reminder(date: max(date, now.addingTimeInterval(15 * 60)))
        case .tomorrowMorning:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 9
            components.minute = 0
            return Reminder(date: calendar.date(from: components) ?? tomorrow)
        case .custom:
            return Reminder(date: customDate)
        }
    }
}
