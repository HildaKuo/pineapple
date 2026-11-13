import Observation
import SwiftUI

@Observable
final class RestTimer {
    var endDate: Date?
    var total: TimeInterval = 0
    /// Increments each time a rest period runs out. Used to trigger haptics.
    var finishCount = 0

    func start(seconds: Int) {
        total = TimeInterval(seconds)
        endDate = .now.addingTimeInterval(total)
    }

    func adjust(by seconds: TimeInterval) {
        guard let endDate else { return }
        let newEnd = endDate.addingTimeInterval(seconds)
        if newEnd <= .now {
            stop()
        } else {
            self.endDate = newEnd
            total = max(total + seconds, newEnd.timeIntervalSinceNow)
        }
    }

    func stop() {
        endDate = nil
    }

    func finish() {
        endDate = nil
        finishCount += 1
    }
}

struct RestTimerBar: View {
    let timer: RestTimer

    var body: some View {
        if let end = timer.endDate {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = max(0, end.timeIntervalSince(context.date))
                VStack(spacing: 8) {
                    HStack {
                        Label("Rest", systemImage: "timer")
                            .font(.subheadline.bold())
                        Spacer()
                        Text(formatDuration(remaining.rounded(.up)))
                            .font(.title3.monospacedDigit().bold())
                    }
                    ProgressView(value: min(remaining, timer.total), total: max(timer.total, 1))
                    HStack {
                        Button("−15s") { timer.adjust(by: -15) }
                        Spacer()
                        Button("+15s") { timer.adjust(by: 15) }
                        Spacer()
                        Button("Skip") { timer.stop() }
                            .bold()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, 4)
            .task(id: end) {
                let wait = end.timeIntervalSinceNow
                if wait > 0 {
                    try? await Task.sleep(for: .seconds(wait))
                }
                if !Task.isCancelled, timer.endDate == end {
                    timer.finish()
                }
            }
        }
    }
}
