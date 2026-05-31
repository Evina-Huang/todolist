import SwiftUI

struct RoutineEditorView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationScheduler) private var notifications

    let routine: Routine?
    let sourceTask: TodoTask?

    @State private var title = ""
    @State private var frequency: RoutineFrequency = .weekly
    @State private var weekday = Calendar.current.component(.weekday, from: Date())
    @State private var monthDay = Calendar.current.component(.day, from: Date())
    @State private var hasReminder = false
    @State private var reminderTime = Date()

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("日程名称", text: $title)
                        .font(.body)
                }

                Section("重复") {
                    Picker("频率", selection: $frequency) {
                        ForEach(RoutineFrequency.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)

                    if frequency == .weekly {
                        Picker("星期", selection: $weekday) {
                            ForEach(1...7, id: \.self) { day in
                                Text(Routine.weekdaySymbols[day - 1]).tag(day)
                            }
                        }
                    }

                    if frequency == .monthly {
                        Stepper("每月 \(monthDay) 日", value: $monthDay, in: 1...31)
                    }
                }

                Section("提醒") {
                    Toggle("提醒我", isOn: $hasReminder)

                    if hasReminder {
                        DatePicker("时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(QuietColor.background)
            .navigationTitle(routine == nil ? "日程" : "编辑日程")
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
            .onAppear(perform: loadRoutine)
        }
        .tint(QuietColor.sage)
    }

    init(routine: Routine? = nil, sourceTask: TodoTask? = nil) {
        self.routine = routine
        self.sourceTask = sourceTask
    }

    private func loadRoutine() {
        if let sourceTask {
            title = sourceTask.title
            if let reminder = sourceTask.reminder {
                hasReminder = true
                reminderTime = reminder.date
            }
            return
        }

        guard let routine else { return }

        title = routine.title
        frequency = routine.frequency
        weekday = routine.weekday
        monthDay = routine.monthDay
        hasReminder = routine.reminderTime != nil
        reminderTime = routine.reminderTime ?? Date()
    }

    private func save() {
        if var routine {
            routine.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            routine.frequency = frequency
            routine.weekday = weekday
            routine.monthDay = monthDay
            routine.reminderTime = hasReminder ? reminderTime : nil
            store.updateRoutine(routine)
        } else if let sourceTask {
            store.addRoutine(
                from: sourceTask,
                title: title,
                frequency: frequency,
                weekday: weekday,
                monthDay: monthDay,
                reminderTime: hasReminder ? reminderTime : nil
            )
        } else {
            store.addRoutine(
                title: title,
                frequency: frequency,
                weekday: weekday,
                monthDay: monthDay,
                reminderTime: hasReminder ? reminderTime : nil
            )
        }

        Task {
            await notifications.rescheduleAll(tasks: store.tasks, routines: store.routines)
        }
        dismiss()
    }
}
