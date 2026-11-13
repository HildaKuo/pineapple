import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]
    @AppStorage(AppSettings.unitKey) private var unit: WeightUnit = .localeDefault

    var body: some View {
        Group {
            if workouts.isEmpty {
                ContentUnavailableView(
                    "No workouts yet",
                    systemImage: "clock",
                    description: Text("Finished workouts show up here.")
                )
            } else {
                List {
                    ForEach(workouts) { workout in
                        NavigationLink {
                            WorkoutDetailView(workout: workout)
                        } label: {
                            WorkoutSummaryRow(workout: workout, unit: unit)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { context.delete(workouts[index]) }
                    }
                }
            }
        }
        .navigationTitle("History")
    }
}

struct WorkoutSummaryRow: View {
    let workout: Workout
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.name).font(.headline)
            Text(workout.startedAt, format: .dateTime.weekday().month().day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Label(formatDuration(workout.duration), systemImage: "stopwatch")
                Label(unit.format(workout.volume), systemImage: "scalemass")
                Label("\(workout.completedSets.count) sets", systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text(workout.sortedEntries.compactMap { $0.exercise?.name }.joined(separator: ", "))
                .font(.caption)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var context
    let workout: Workout
    @AppStorage(AppSettings.unitKey) private var unit: WeightUnit = .localeDefault
    @State private var savedRoutine = false

    var body: some View {
        List {
            Section {
                LabeledContent("Date") {
                    Text(workout.startedAt, format: .dateTime.weekday().month().day().year().hour().minute())
                }
                LabeledContent("Duration", value: formatDuration(workout.duration))
                LabeledContent("Volume", value: unit.format(workout.volume))
                LabeledContent("Sets", value: "\(workout.completedSets.count)")
            }

            ForEach(workout.sortedEntries) { entry in
                Section(entry.exercise?.name ?? "Deleted exercise") {
                    ForEach(Array(entry.sortedSets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("\(index + 1)")
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .leading)
                            Text("\(unit.format(set.weight)) × \(set.reps)")
                                .monospacedDigit()
                            Spacer()
                            Text("1RM \(unit.format(set.estimatedOneRepMax))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button("Save as Routine", systemImage: "square.and.arrow.down") { saveAsRoutine() }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .alert("Routine saved", isPresented: $savedRoutine) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Find it on the Workout tab.")
        }
    }

    private func saveAsRoutine() {
        let routine = Routine(name: workout.name)
        context.insert(routine)
        for (index, entry) in workout.sortedEntries.enumerated() {
            guard let exercise = entry.exercise else { continue }
            let item = RoutineItem(order: index, setCount: max(entry.sets.count, 1))
            context.insert(item)
            item.exercise = exercise
            item.routine = routine
        }
        savedRoutine = true
    }
}
