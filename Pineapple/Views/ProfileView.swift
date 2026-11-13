import SwiftData
import SwiftUI

struct ProfileView: View {
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]
    @AppStorage(AppSettings.unitKey) private var unit: WeightUnit = .localeDefault
    @AppStorage(AppSettings.restKey) private var restSeconds = AppSettings.defaultRest

    private let restOptions = [30, 45, 60, 90, 120, 150, 180, 240, 300]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        StatTile(title: "Workouts", value: "\(workouts.count)")
                        StatTile(title: "This week", value: "\(workoutsThisWeek)")
                        StatTile(title: "Total volume", value: unit.format(workouts.reduce(0) { $0 + $1.volume }))
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
                }

                Section("Recent Workouts") {
                    if workouts.isEmpty {
                        Text("Finished workouts show up here.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(workouts.prefix(3)) { workout in
                        NavigationLink {
                            WorkoutDetailView(workout: workout)
                        } label: {
                            WorkoutSummaryRow(workout: workout, unit: unit)
                        }
                    }
                }

                Section("Progress") {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("Workout History", systemImage: "clock.arrow.circlepath")
                    }
                    NavigationLink {
                        ExerciseLibraryView()
                    } label: {
                        Label("Exercises & Records", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }

                Section {
                    Picker("Weight unit", selection: $unit) {
                        ForEach(WeightUnit.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Rest timer", selection: $restSeconds) {
                        ForEach(restOptions, id: \.self) { seconds in
                            Text(formatDuration(TimeInterval(seconds))).tag(seconds)
                        }
                    }
                } header: {
                    Text("Settings")
                } footer: {
                    Text("The rest timer starts when you check off a set.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var workoutsThisWeek: Int {
        workouts.filter { Calendar.current.isDate($0.startedAt, equalTo: .now, toGranularity: .weekOfYear) }.count
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
