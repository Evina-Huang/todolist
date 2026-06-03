import SwiftUI

struct TaskRow: View {
    let task: TodoTask
    @Binding var editingTaskID: TodoTask.ID?
    let toggleCompletion: () -> Void
    let saveTitle: (String) -> Void
    let pinTask: (() -> Void)?

    @FocusState private var isTitleFocused: Bool
    @State private var draftTitle: String

    init(
        task: TodoTask,
        editingTaskID: Binding<TodoTask.ID?>,
        toggleCompletion: @escaping () -> Void,
        saveTitle: @escaping (String) -> Void,
        pinTask: (() -> Void)? = nil
    ) {
        self.task = task
        self._editingTaskID = editingTaskID
        self.toggleCompletion = toggleCompletion
        self.saveTitle = saveTitle
        self.pinTask = pinTask
        self._draftTitle = State(initialValue: task.title)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: toggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(task.isCompleted ? QuietColor.sage : QuietColor.mist)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "标记为未完成" : "标记为完成")

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("待办内容", text: $draftTitle, axis: .vertical)
                        .font(.system(size: 18, weight: .regular))
                        .lineLimit(nil)
                        .foregroundStyle(task.isCompleted ? QuietColor.secondaryInk.opacity(0.62) : QuietColor.ink)
                        .strikethrough(task.isCompleted, color: QuietColor.secondaryInk.opacity(0.62))
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .focused($isTitleFocused)
                        .fixedSize(horizontal: false, vertical: true)
                        .onTapGesture {
                            editingTaskID = task.id
                        }
                        .onSubmit(commitTitle)
                        .onChange(of: draftTitle) { _, newValue in
                            guard newValue.rangeOfCharacter(from: .newlines) != nil else { return }
                            draftTitle = TodoTask.sanitizedTitle(newValue)
                            commitTitle()
                        }

                    if task.isRoutineInstance {
                        Text("日程")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(QuietColor.sage)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(QuietColor.mist.opacity(0.24))
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                Spacer(minLength: 12)

                if let reminder = task.reminder {
                    Text(reminder.timeLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(task.isCompleted ? QuietColor.secondaryInk.opacity(0.56) : QuietColor.secondaryInk)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.top, 2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                editingTaskID = task.id
                isTitleFocused = true
            }

            if let pinTask {
                Button(action: pinTask) {
                    Image(systemName: "repeat")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(QuietColor.sage)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("加入日程")
            }
        }
        .padding(.vertical, 10)
        .onChange(of: task.title) { _, newValue in
            guard !isTitleFocused else { return }
            draftTitle = newValue
        }
        .onChange(of: editingTaskID) { _, newValue in
            if newValue == task.id {
                isTitleFocused = true
            } else if isTitleFocused {
                commitTitle()
                isTitleFocused = false
            }
        }
        .onChange(of: isTitleFocused) { _, isFocused in
            if isFocused {
                editingTaskID = task.id
            } else if editingTaskID == task.id {
                commitTitle()
                editingTaskID = nil
            }
        }
    }

    private func commitTitle() {
        let trimmedTitle = TodoTask.sanitizedTitle(draftTitle)
        guard !trimmedTitle.isEmpty else {
            draftTitle = task.title
            return
        }

        if trimmedTitle != task.title {
            saveTitle(trimmedTitle)
        }
        draftTitle = trimmedTitle
    }
}
