import Charts
import SwiftData
import SwiftUI

// MARK: - Shared pieces

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name)
            Text(exercise.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct MuscleFilterBar: View {
    @Binding var selection: MuscleGroup?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", isSelected: selection == nil) { selection = nil }
                ForEach(MuscleGroup.allCases) { muscle in
                    chip(muscle.title, isSelected: selection == muscle) { selection = muscle }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemFill), in: Capsule())
                .foregroundStyle(isSelected ? Color.black : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

func filterExercises(_ exercises: [Exercise], search: String, muscle: MuscleGroup?) -> [Exercise] {
    exercises.filter { exercise in
        (muscle == nil || exercise.muscleRaw == muscle?.rawValue)
            && (search.isEmpty || exercise.name.localizedCaseInsensitiveContains(search))
    }
}

// MARK: - Picker

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var muscle: MuscleGroup?
    @State private var showingNew = false
    @State private var created: Exercise?

    let onPick: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            List(filterExercises(exercises, search: search, muscle: muscle)) { exercise in
                Button {
                    onPick(exercise)
                    dismiss()
                } label: {
                    ExerciseRow(exercise: exercise)
                }
                .tint(.primary)
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top, spacing: 0) {
                MuscleFilterBar(selection: $muscle)
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New", systemImage: "plus") { showingNew = true }
                }
            }
            .sheet(isPresented: $showingNew, onDismiss: {
                if let created {
                    onPick(created)
                    dismiss()
                }
            }) {
                NewExerciseView { created = $0 }
            }
        }
    }
}

// MARK: - New exercise

struct NewExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var muscle: MuscleGroup = .chest
    @State private var equipment: Equipment = .barbell

    var onCreate: ((Exercise) -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Muscle group", selection: $muscle) {
                    ForEach(MuscleGroup.allCases) { Text($0.title).tag($0) }
                }
                Picker("Equipment", selection: $equipment) {
                    ForEach(Equipment.allCases) { Text($0.title).tag($0) }
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let exercise = Exercise(name: trimmedName, muscle: muscle, equipment: equipment, isCustom: true)
        context.insert(exercise)
        onCreate?(exercise)
        dismiss()
    }
}

// MARK: - Exercise list (opened from Profile)

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var muscle: MuscleGroup?
    @State private var showingNew = false

    var body: some View {
        List {
            ForEach(filterExercises(exercises, search: search, muscle: muscle)) { exercise in
                NavigationLink {
                    ExerciseDetailView(exercise: exercise)
                } label: {
                    ExerciseRow(exercise: exercise)
                }
                .deleteDisabled(!exercise.isCustom)
            }
            .onDelete { offsets in
                let visible = filterExercises(exercises, search: search, muscle: muscle)
                for index in offsets where visible[index].isCustom {
                    context.delete(visible[index])
                }
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .top, spacing: 0) {
            MuscleFilterBar(selection: $muscle)
        }
        .searchable(text: $search)
        .navigationTitle("Exercises")
        .toolbar {
            Button("New Exercise", systemImage: "plus") { showingNew = true }
        }
        .sheet(isPresented: $showingNew) {
            NewExerciseView()
        }
    }
}

// MARK: - Detail and progress

enum ProgressMetric: String, CaseIterable, Identifiable {
    case estimatedMax, heaviest, volume

    var id: String { rawValue }

    var title: String {
        switch self {
        case .estimatedMax: return "Est. 1RM"
        case .heaviest: return "Heaviest"
        case .volume: return "Volume"
        }
    }

    func value(for session: ExerciseSession) -> Double {
        switch self {
        case .estimatedMax: return session.bestEstimatedMax
        case .heaviest: return session.heaviest
        case .volume: return session.volume
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @AppStorage(AppSettings.unitKey) private var unit: WeightUnit = .localeDefault
    @State private var metric: ProgressMetric = .estimatedMax

    var body: some View {
        let sessions = exercise.sessions
        let allSets = sessions.flatMap(\.sets)

        List {
            Section {
                Picker("Metric", selection: $metric) {
                    ForEach(ProgressMetric.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                if sessions.isEmpty {
                    Text("Finish a workout with this exercise to see your progress.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .multilineTextAlignment(.center)
                } else {
                    Chart(sessions) { session in
                        LineMark(
                            x: .value("Date", session.date),
                            y: .value(metric.title, unit.display(metric.value(for: session)))
                        )
                        .interpolationMethod(.monotone)
                        PointMark(
                            x: .value("Date", session.date),
                            y: .value(metric.title, unit.display(metric.value(for: session)))
                        )
                    }
                    .foregroundStyle(Color.accentColor)
                    .chartYAxisLabel(unit.rawValue)
                    .frame(height: 220)
                }
            } header: {
                Text(exercise.subtitle)
            }

            if !allSets.isEmpty {
                Section("Personal Records") {
                    LabeledContent("Heaviest weight", value: unit.format(allSets.map(\.weight).max() ?? 0))
                    LabeledContent("Best est. 1RM", value: unit.format(allSets.map(\.estimatedOneRepMax).max() ?? 0))
                    if let best = allSets.max(by: { $0.volume < $1.volume }) {
                        LabeledContent("Best set", value: "\(unit.format(best.weight)) × \(best.reps)")
                    }
                    LabeledContent("Best session volume", value: unit.format(sessions.map(\.volume).max() ?? 0))
                    LabeledContent("Most reps", value: "\(allSets.map(\.reps).max() ?? 0)")
                }

                Section("History") {
                    ForEach(Array(sessions.reversed())) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.date, format: .dateTime.weekday().month().day().year())
                                .font(.subheadline.bold())
                            ForEach(Array(session.sets.enumerated()), id: \.offset) { index, set in
                                Text("\(index + 1).  \(unit.format(set.weight)) × \(set.reps)")
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
    }
}
