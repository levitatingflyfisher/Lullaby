import SwiftUI
import WidgetKit

private let appGroupId = "group.com.example.lullaby"

// MARK: - Timeline Entry

struct LullabyEntry: TimelineEntry {
    let date: Date
    let babyName: String
    let lastFeedAgo: String
    let lastSleepAgo: String
    let lastDiaperAgo: String
    let activeTimerType: String?
    let activeTimerStart: Date?
}

// MARK: - Timeline Provider

struct LullabyProvider: TimelineProvider {
    func placeholder(in context: Context) -> LullabyEntry {
        LullabyEntry(
            date: Date(),
            babyName: "Baby",
            lastFeedAgo: "–",
            lastSleepAgo: "–",
            lastDiaperAgo: "–",
            activeTimerType: nil,
            activeTimerStart: nil
        )
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (LullabyEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<LullabyEntry>) -> Void) {
        let entry = readEntry()
        // policy: .never — Flutter drives all refreshes via HomeWidget.updateWidget()
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func readEntry() -> LullabyEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let babyName  = defaults?.string(forKey: "lullaby.baby_name")       ?? "–"
        let feedAgo   = defaults?.string(forKey: "lullaby.last_feed_ago")   ?? "–"
        let sleepAgo  = defaults?.string(forKey: "lullaby.last_sleep_ago")  ?? "–"
        let diaperAgo = defaults?.string(forKey: "lullaby.last_diaper_ago") ?? "–"
        let timerType = defaults?.string(forKey: "lullaby.active_timer_type")

        var timerStart: Date?
        if let startStr = defaults?.string(forKey: "lullaby.active_timer_start") {
            timerStart = ISO8601DateFormatter().date(from: startStr)
        }

        return LullabyEntry(
            date: Date(),
            babyName: babyName,
            lastFeedAgo: feedAgo,
            lastSleepAgo: sleepAgo,
            lastDiaperAgo: diaperAgo,
            activeTimerType: timerType,
            activeTimerStart: timerStart
        )
    }
}

// MARK: - Widget View

struct LullabyWidgetEntryView: View {
    var entry: LullabyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.babyName)
                .font(.headline)
                .lineLimit(1)

            if let timerStart = entry.activeTimerStart {
                HStack {
                    Text(entry.activeTimerType == "feeding" ? "🍼" : "😴")
                    Spacer()
                    // Text(date:style:.timer) counts up natively every second
                    // without a Flutter call. Requires iOS 14+.
                    Text(timerStart, style: .timer)
                        .monospacedDigit()
                }
            }

            HStack {
                Text("🍼 Fed")
                Spacer()
                Text(entry.lastFeedAgo)
            }
            .font(.caption)

            HStack {
                Text("😴 Nap")
                Spacer()
                Text(entry.lastSleepAgo)
            }
            .font(.caption)

            HStack {
                Text("💧 Changed")
                Spacer()
                Text(entry.lastDiaperAgo)
            }
            .font(.caption)
        }
        .padding(10)
        .widgetBackground()
    }
}

// MARK: - iOS 17 containerBackground / iOS <17 fallback

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(UIColor.systemBackground))
        }
    }
}

// MARK: - Widget Configuration

@main
struct LullabyWidget: Widget {
    let kind: String = "LullabyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LullabyProvider()) { entry in
            LullabyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lullaby")
        .description("Baby name, active timer, and event recency at a glance.")
        .supportedFamilies([.systemSmall])
    }
}
