import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TaskRow: View {
    let task: TodoTask
    @Binding var editingTaskID: TodoTask.ID?
    let toggleCompletion: () -> Void
    let saveTitle: (String) -> Void

    @FocusState private var isTitleFocused: Bool
    @State private var draftTitle: String

    init(
        task: TodoTask,
        editingTaskID: Binding<TodoTask.ID?>,
        toggleCompletion: @escaping () -> Void,
        saveTitle: @escaping (String) -> Void
    ) {
        self.task = task
        self._editingTaskID = editingTaskID
        self.toggleCompletion = toggleCompletion
        self.saveTitle = saveTitle
        self._draftTitle = State(initialValue: task.title)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            SatisfyingCompletionButton(
                isCompleted: task.isCompleted,
                action: toggleCompletion
            )
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
                            commitTitle(from: newValue)
                            editingTaskID = nil
                            isTitleFocused = false
                        }
                        .animation(.easeOut(duration: 0.18), value: task.isCompleted)

                    if task.isPinned || task.isRoutineInstance {
                        HStack(spacing: 6) {
                            if task.isPinned {
                                Label("置顶", systemImage: "pin.fill")
                                    .labelStyle(.titleAndIcon)
                            }

                            if task.isRoutineInstance {
                                Text("日程")
                            }
                        }
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
        }
        .padding(.vertical, 10)
        .animation(.spring(response: 0.3, dampingFraction: 0.74), value: task.isCompleted)
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
        commitTitle(from: draftTitle)
    }

    private func commitTitle(from text: String) {
        let trimmedTitle = TodoTask.sanitizedTitle(text)
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

private struct SatisfyingCompletionButton: View {
    let isCompleted: Bool
    let action: () -> Void

    @State private var strikeProgress: CGFloat = 0
    @State private var impactOpacity = 0.0

    var body: some View {
        Button {
            playFeedback(wasCompleted: isCompleted)

            withAnimation(.spring(response: 0.26, dampingFraction: 0.58)) {
                action()
            }
        } label: {
            ZStack {
                impactShadow

                if !isCompleted {
                    Rectangle()
                        .stroke(QuietColor.mist.opacity(0.9), lineWidth: 1.6)
                        .frame(width: 25, height: 25)
                }

                HeavyCheckmark()
                    .trim(from: 0, to: isCompleted ? 1 : 0)
                    .stroke(
                        QuietColor.sage,
                        style: StrokeStyle(lineWidth: 5.6, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 30, height: 24)
                    .scaleEffect(isCompleted ? 1.0 : 0.72)
                    .rotationEffect(.degrees(isCompleted ? -4 : -18))
                    .offset(x: 1, y: isCompleted ? -1 : 5)
                    .shadow(color: QuietColor.sage.opacity(0.28), radius: 7, x: 0, y: 3)
                    .opacity(isCompleted ? 1 : 0)
            }
            .frame(width: 50, height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(HeavyCheckPressStyle())
        .onChange(of: isCompleted) { _, completed in
            guard completed else { return }
            fireImpact()
        }
    }

    private var impactShadow: some View {
        Ellipse()
            .fill(QuietColor.sage.opacity(impactOpacity))
            .frame(width: 34 + (strikeProgress * 14), height: 8 + (strikeProgress * 2))
            .scaleEffect(x: 1 + (strikeProgress * 0.26), y: 1, anchor: .center)
            .offset(y: 16)
            .blur(radius: 2.5)
            .allowsHitTesting(false)
    }

    private func fireImpact() {
        strikeProgress = 0
        impactOpacity = 0.34

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.42)) {
                strikeProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.18)) {
                impactOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            strikeProgress = 0
        }
    }

    private func playFeedback(wasCompleted: Bool) {
        #if canImport(UIKit)
        if wasCompleted {
            UISelectionFeedbackGenerator().selectionChanged()
        } else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.86)
        }
        #endif
    }
}

private struct HeavyCheckPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.78 : 1)
            .rotationEffect(.degrees(configuration.isPressed ? 2 : 0))
            .offset(y: configuration.isPressed ? 5 : 0)
            .animation(.spring(response: 0.15, dampingFraction: 0.42), value: configuration.isPressed)
    }
}

private struct HeavyCheckmark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.midY + rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.02, y: rect.minY + rect.height * 0.04))
        return path
    }
}
