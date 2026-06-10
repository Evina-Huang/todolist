import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: TodayWidgetEntry

    private var snapshot: TodayWidgetSnapshot {
        entry.snapshot
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumBody
            default:
                smallBody
            }
        }
        .containerBackground(WidgetColor.background, for: .widget)
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            widgetHeader

            Spacer(minLength: 10)

            if let task = snapshot.tasks.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(WidgetColor.ink)
                        .lineLimit(3)
                        .minimumScaleFactor(0.74)

                    taskMeta(for: task)
                }
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    Text("现在很清静")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(WidgetColor.ink)
                        .lineLimit(1)

                    Text("有事时写下，没事时留白。")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(WidgetColor.secondaryInk)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            progressFooter
        }
        .padding(16)
    }

    private var mediumBody: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                widgetHeader

                Spacer(minLength: 10)

                Text(snapshot.remainingCount == 0 ? "今日留白" : "还剩 \(snapshot.remainingCount) 件")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(WidgetColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 12)

                progressFooter
            }
            .frame(width: 114, alignment: .leading)

            Rectangle()
                .fill(WidgetColor.line.opacity(0.75))
                .frame(width: 1)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                if snapshot.tasks.isEmpty {
                    emptyMediumTasks
                } else {
                    ForEach(Array(snapshot.tasks.prefix(3).enumerated()), id: \.element.id) { index, task in
                        taskLine(task, isFirst: index == 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var widgetHeader: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(WidgetColor.sage)
                .frame(width: 7, height: 7)

            Text(WidgetDateFormatter.header.string(from: snapshot.date))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WidgetColor.secondaryInk)
                .lineLimit(1)
        }
    }

    private var progressFooter: some View {
        VStack(alignment: .leading, spacing: 7) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WidgetColor.mist.opacity(0.42))

                    Capsule()
                        .fill(WidgetColor.sage)
                        .frame(width: max(proxy.size.width * snapshot.progress, snapshot.progress > 0 ? 8 : 0))
                }
            }
            .frame(height: 6)

            if !progressCaption.isEmpty {
                Text(progressCaption)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetColor.secondaryInk)
                    .lineLimit(1)
            }
        }
    }

    private var progressCaption: String {
        guard snapshot.totalCount > 0 else { return "" }
        return "\(snapshot.completedCount)/\(snapshot.totalCount) 已完成"
    }

    private var emptyMediumTasks: some View {
        Text("现在很清静")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(WidgetColor.ink)
            .lineLimit(1)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func taskLine(_ task: TodayWidgetTask, isFirst: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Image(systemName: isFirst ? "circle.fill" : "circle")
                .font(.system(size: isFirst ? 8 : 9, weight: .semibold))
                .foregroundStyle(isFirst ? WidgetColor.sage : WidgetColor.mist)
                .frame(width: 11)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: isFirst ? 15 : 13, weight: isFirst ? .semibold : .regular))
                    .foregroundStyle(WidgetColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                taskMeta(for: task)
            }
        }
    }

    @ViewBuilder
    private func taskMeta(for task: TodayWidgetTask) -> some View {
        if let reminderDate = task.reminderDate {
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text(WidgetDateFormatter.time.string(from: reminderDate))
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(WidgetColor.secondaryInk)
            .lineLimit(1)
        } else if task.isRoutineInstance {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10, weight: .semibold))
                Text("例行")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(WidgetColor.secondaryInk)
            .lineLimit(1)
        }
    }
}

private enum WidgetColor {
    static let background = Color(red: 0.965, green: 0.957, blue: 0.925)
    static let ink = Color(red: 0.115, green: 0.122, blue: 0.108)
    static let secondaryInk = Color(red: 0.430, green: 0.455, blue: 0.407)
    static let mist = Color(red: 0.785, green: 0.818, blue: 0.745)
    static let sage = Color(red: 0.376, green: 0.506, blue: 0.420)
    static let line = Color(red: 0.855, green: 0.850, blue: 0.800)
}

private enum WidgetDateFormatter {
    static let header: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

#Preview(as: .systemSmall) {
    QuietTodayWidget()
} timeline: {
    TodayWidgetEntry(date: Date(), snapshot: .placeholder)
    TodayWidgetEntry(date: Date(), snapshot: .empty)
}

#Preview(as: .systemMedium) {
    QuietTodayWidget()
} timeline: {
    TodayWidgetEntry(date: Date(), snapshot: .placeholder)
    TodayWidgetEntry(date: Date(), snapshot: .empty)
}
