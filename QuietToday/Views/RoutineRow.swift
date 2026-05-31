import SwiftUI

struct RoutineRow: View {
    let routine: Routine
    let openEditor: () -> Void

    var body: some View {
        Button(action: openEditor) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(QuietColor.sage)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(QuietColor.mist.opacity(0.22))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(routine.title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(QuietColor.ink)

                    HStack(spacing: 8) {
                        Text(routine.cadenceLabel)
                        if let reminderLabel = routine.reminderLabel {
                            Text(reminderLabel)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(QuietColor.secondaryInk)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(QuietColor.mist)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(QuietColor.surface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(QuietColor.line.opacity(0.58), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch routine.frequency {
        case .daily:
            "sun.max"
        case .weekly:
            "calendar"
        case .monthly:
            "calendar.badge.clock"
        }
    }
}
