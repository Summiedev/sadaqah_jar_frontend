import WidgetKit
import SwiftUI

// MARK: - Daily Verse Widget
struct MizanWidgetEntry: TimelineEntry {
    let date: Date
    let text: String
    let source: String
    let shortText: String
}

struct MizanWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MizanWidgetEntry {
        MizanWidgetEntry(date: Date(), text: "Remember Allah with much remembrance.", source: "Quran 33:41-42", shortText: "Remember Allah often")
    }

    func getSnapshot(in context: Context, completion: @escaping (MizanWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MizanWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> MizanWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.example.sadaqahJar")
        let text = defaults?.string(forKey: "daily_text") ?? "Remember Allah with much remembrance."
        let source = defaults?.string(forKey: "daily_source") ?? "Quran 33:41-42"
        let shortText = defaults?.string(forKey: "daily_short") ?? "Remember Allah often"
        return MizanWidgetEntry(date: Date(), text: text, source: source, shortText: shortText)
    }
}

struct MizanLockScreenWidgetEntryView: View {
    var entry: MizanWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            InlineView(entry: entry)
        default:
            RectangularView(entry: entry)
        }
    }
}

struct RectangularView: View {
    let entry: MizanWidgetEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("A gentle reminder")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Text(entry.text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
            Text(entry.source)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct InlineView: View {
    let entry: MizanWidgetEntry
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 11))
            Text(entry.shortText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct MizanLockScreenWidget: Widget {
    let kind: String = "MizanLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MizanWidgetProvider()) { entry in
            MizanLockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Mizan")
        .description("A gentle reminder for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Next Prayer Widget
struct NextPrayerEntry: TimelineEntry {
    let date: Date
    let prayerName: String
    let countdown: String
}

struct NextPrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextPrayerEntry {
        NextPrayerEntry(date: Date(), prayerName: "Asr", countdown: "45 min")
    }

    func getSnapshot(in context: Context, completion: @escaping (NextPrayerEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextPrayerEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> NextPrayerEntry {
        let defaults = UserDefaults(suiteName: "group.com.example.sadaqahJar")
        let prayerName = defaults?.string(forKey: "prayer_name") ?? "Asr"
        let countdown = defaults?.string(forKey: "prayer_countdown") ?? "45"
        return NextPrayerEntry(date: Date(), prayerName: prayerName, countdown: "\(countdown) min")
    }
}

struct NextPrayerWidgetEntryView: View {
    var entry: NextPrayerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            NextPrayerInlineView(entry: entry)
        default:
            NextPrayerRectangularView(entry: entry)
        }
    }
}

struct NextPrayerRectangularView: View {
    let entry: NextPrayerEntry
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "mosque.fill")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.prayerName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("in \(entry.countdown)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct NextPrayerInlineView: View {
    let entry: NextPrayerEntry
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mosque.fill")
                .font(.system(size: 11))
            Text("\(entry.prayerName) in \(entry.countdown)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct NextPrayerWidget: Widget {
    let kind: String = "MizanNextPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextPrayerProvider()) { entry in
            NextPrayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Prayer")
        .description("Countdown to the next salah.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Streak Progress Widget
struct StreakProgressEntry: TimelineEntry {
    let date: Date
    let mode: String
    let value: String
    let percentage: Double
}

struct StreakProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakProgressEntry {
        StreakProgressEntry(date: Date(), mode: "streak", value: "14", percentage: 0.6)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakProgressEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakProgressEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> StreakProgressEntry {
        let defaults = UserDefaults(suiteName: "group.com.example.sadaqahJar")
        let streak = defaults?.integer(forKey: "streak_count") ?? 0
        let progressPct = defaults?.integer(forKey: "goal_progress_pct") ?? 0
        let mode = streak > 0 ? "streak" : "goal"
        let value = mode == "streak" ? "\(streak)" : "\(progressPct)"
        let progress = Double(progressPct) / 100.0
        return StreakProgressEntry(date: Date(), mode: mode, value: value, percentage: progress)
    }
}

struct StreakProgressWidgetEntryView: View {
    var entry: StreakProgressEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if family == .systemSmall {
            StreakProgressInlineView(entry: entry)
        } else {
            StreakProgressRectangularView(entry: entry)
        }
    }
}

struct StreakProgressRectangularView: View {
    let entry: StreakProgressEntry
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .trim(from: 0.0, to: CGFloat(entry.percentage))
                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .foregroundStyle(.secondary)
                Circle()
                    .stroke(.secondary.opacity(0.2), lineWidth: 4)
                Text(entry.value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.mode == "streak" ? "Day streak" : "Monthly progress")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(entry.mode == "streak" ? "Keep going" : "\(Int(entry.percentage * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct StreakProgressInlineView: View {
    let entry: StreakProgressEntry
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.mode == "streak" ? "flame.fill" : "chart.line.uptrend.xyaxis")
                .font(.system(size: 11))
            Text(entry.mode == "streak" ? "\(entry.value) days" : "\(entry.value)% this month")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct StreakProgressWidget: Widget {
    let kind: String = "MizanStreakProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProgressProvider()) { entry in
            StreakProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your journey at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct MizanWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        MizanLockScreenWidget()
        NextPrayerWidget()
        StreakProgressWidget()
    }
}
