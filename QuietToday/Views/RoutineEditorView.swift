import SwiftUI

struct RoutineEditorView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationScheduler) private var notifications

    let routine: Routine?
    let sourceTask: TodoTask?

    @State private var title = ""
    @State private var frequency: RoutineFrequency = .monthly
    @State private var weekday = Calendar.current.component(.weekday, from: Date())
    @State private var monthDay = 25
    @State private var hasReminder = true
    @State private var reminders: [RoutineReminder] = [RoutineReminder()]

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
                        ForEach(reminders.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(reminderTitle(for: index))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(QuietColor.ink)

                                    Spacer()

                                    if reminders.count > 1 {
                                        Button(role: .destructive) {
                                            deleteReminder(at: index)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.borderless)
                                        .accessibilityLabel("删除\(reminderTitle(for: index))")
                                    }
                                }

                                if frequency == .monthly {
                                    Picker("日期", selection: $reminders[index].leadTime) {
                                        ForEach(RoutineReminderLeadTime.allCases) { leadTime in
                                            Text(leadTime.title).tag(leadTime)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                DatePicker("时间", selection: $reminders[index].time, displayedComponents: .hourAndMinute)
                            }
                        }

                        Button {
                            addReminder()
                        } label: {
                            Label("添加提醒", systemImage: "plus.circle.fill")
                        }
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
            .onChange(of: hasReminder) { _, isOn in
                if isOn && reminders.isEmpty {
                    reminders = [RoutineReminder()]
                }
            }
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
            frequency = .monthly
            monthDay = 25
            if let reminder = sourceTask.reminder {
                hasReminder = true
                reminders = [RoutineReminder(time: reminder.date)]
            }
            return
        }

        guard let routine else { return }

        title = routine.title
        frequency = routine.frequency
        weekday = routine.weekday
        monthDay = routine.monthDay
        hasReminder = !routine.reminders.isEmpty
        reminders = routine.reminders.isEmpty ? [RoutineReminder()] : routine.reminders
    }

    private func save() {
        let savedReminders = hasReminder ? reminders : []

        if var routine {
            routine.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            routine.frequency = frequency
            routine.weekday = weekday
            routine.monthDay = monthDay
            routine.reminders = savedReminders
            store.updateRoutine(routine)
        } else if let sourceTask {
            store.addRoutine(
                from: sourceTask,
                title: title,
                frequency: frequency,
                weekday: weekday,
                monthDay: monthDay,
                reminders: savedReminders
            )
        } else {
            store.addRoutine(
                title: title,
                frequency: frequency,
                weekday: weekday,
                monthDay: monthDay,
                reminders: savedReminders
            )
        }

        Task {
            await notifications.rescheduleAll(tasks: store.tasks, routines: store.routines)
        }
        dismiss()
    }

    private func addReminder() {
        reminders.append(RoutineReminder())
    }

    private func deleteReminder(at index: Int) {
        guard reminders.indices.contains(index) else { return }
        reminders.remove(at: index)
    }

    private func reminderTitle(for index: Int) -> String {
        switch index {
        case 0:
            "第一次提醒"
        case 1:
            "第二次提醒"
        case 2:
            "第三次提醒"
        default:
            "第 \(index + 1) 次提醒"
        }
    }
}
