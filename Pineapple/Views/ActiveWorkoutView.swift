import SwiftData
import SwiftUI
import UIKit

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Bindable var workout: Workout
    @AppStorage(AppSettings.unitKey) private var unit: WeightUnit = .localeDefault
    @AppStorage(AppSettings.restKey) private var restSeconds = AppSettings.defaultRest

    @State private var timer = RestTimer()
    @State private var showingPicker = false
    @State private var confirmingFinish = false
    @State private var confirmingDiscard = false

    var body: some View {
        List {
            Section {
                TextField("Workout name", text: $workout.name)
                    .font(.title3.bold())
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    LabeledContent("Duration", value: formatDuration(context.date.timeIntervalSince(workout.startedAt)))
                }
                LabeledContent("Volume", value: unit.format(workout.volume))
                LabeledContent("Sets done", value: "\(workout.completedSets.count)")
            }

            ForEach(workout.sortedEntries) { entry in
                ExerciseEntrySection(entry: entry, unit: unit) {
                    timer.start(seconds: restSeconds)
                }
            }

            Section {
                Button {
                    showingPicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(.headline)
                }
            }

            Section {
                Button("Discard Workout", role: .destructive) {
                    confirmingDiscard = true
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Finish") { confirmingFinish = true }
                    .bold()
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            RestTimerBar(timer: timer)
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                WorkoutBuilder.addExercise(exercise, sets: 1, to: workout, in: context)
            }
        }
        .confirmationDialog("Finish workout?", isPresented: $confirmingFinish, titleVisibility: .visible) {
            Button(workout.completedSets.isEmpty ? "Discard Workout" : "Finish") { finish() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text(workout.completedSets.isEmpty
                 ? "No sets are checked off, so this workout will be discarded."
                 : "Sets that aren't checked off will be removed.")
        }
        .confirmationDialog("Discard this workout?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) {
                timer.stop()
                context.delete(workout)
            }
        }
        .sensoryFeedback(.success, trigger: timer.finishCount)
    }

    private func finish() {
        hideKeyboard()
        timer.stop()
        guard !workout.completedSets.isEmpty else {
            context.delete(workout)
            return
        }
        for entry in workout.entries {
            for set in entry.sets where !set.isDone {
                entry.sets.removeAll { $0.persistentModelID == set.persistentModelID }
                context.delete(set)
            }
            if entry.sets.isEmpty {
                workout.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
                context.delete(entry)
            }
        }
        workout.endedAt = .now
        try? context.save()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Exercise section

struct ExerciseEntrySection: View {
    @Environment(\.modelContext) private var context
    @Bindable var entry: WorkoutExercise
    let unit: WeightUnit
    let onSetCompleted: () -> Void

    var body: some View {
        let previous = entry.exercise?.lastCompletedSets ?? []
        Section {
            SetHeaderRow(unit: unit)
            ForEach(Array(entry.sortedSets.enumerated()), id: \.element.id) { index, set in
                SetRow(
                    set: set,
                    number: index + 1,
                    previous: index < previous.count ? previous[index] : nil,
                    unit: unit,
                    onCompleted: onSetCompleted
                )
            }
            .onDelete(perform: deleteSets)

            Button {
                let last = entry.sortedSets.last
                WorkoutBuilder.addSet(to: entry, weight: last?.weight ?? 0, reps: last?.reps ?? 0, in: context)
            } label: {
                Label("Add Set", systemImage: "plus")
            }
        } header: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.exercise?.name ?? "Deleted exercise")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                    if let exercise = entry.exercise {
                        Text(exercise.subtitle).font(.caption)
                    }
                }
                .textCase(nil)
                Spacer()
                Menu {
                    Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                        removeEntry()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3)
                }
            }
        }
    }

    private func deleteSets(at offsets: IndexSet) {
        let sets = entry.sortedSets
        for index in offsets {
            let set = sets[index]
            entry.sets.removeAll { $0.persistentModelID == set.persistentModelID }
            context.delete(set)
        }
        for (index, set) in entry.sortedSets.enumerated() {
            set.order = index
        }
    }

    private func removeEntry() {
        if let workout = entry.workout {
            workout.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
        }
        context.delete(entry)
    }
}

// MARK: - Set rows

private let numberColumnWidth: CGFloat = 28
private let weightColumnWidth: CGFloat = 68
private let repsColumnWidth: CGFloat = 52
private let doneColumnWidth: CGFloat = 32

struct SetHeaderRow: View {
    let unit: WeightUnit

    var body: some View {
        HStack(spacing: 10) {
            Text("SET").frame(width: numberColumnWidth)
            Text("PREVIOUS").frame(maxWidth: .infinity, alignment: .leading)
            Text(unit.rawValue.uppercased()).frame(width: weightColumnWidth)
            Text("REPS").frame(width: repsColumnWidth)
            Image(systemName: "checkmark").frame(width: doneColumnWidth)
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
        .deleteDisabled(true)
    }
}

struct SetRow: View {
    @Bindable var set: WorkoutSet
    let number: Int
    let previous: WorkoutSet?
    let unit: WeightUnit
    let onCompleted: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("\(number)")
                .font(.subheadline.bold())
                .frame(width: numberColumnWidth)

            Button {
                fillFromPrevious()
            } label: {
                Text(previousText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .disabled(previous == nil)

            NumberField(value: weightBinding, allowsDecimal: true)
                .frame(width: weightColumnWidth)

            NumberField(value: repsBinding, allowsDecimal: false)
                .frame(width: repsColumnWidth)

            Button {
                toggleDone()
            } label: {
                Image(systemName: set.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.isDone ? Color.green : Color.secondary)
            }
            .buttonStyle(.borderless)
            .frame(width: doneColumnWidth)
        }
        .listRowBackground(set.isDone ? Color.green.opacity(0.12) : nil)
    }

    private var previousText: String {
        guard let previous else { return "—" }
        return "\(unit.format(previous.weight)) × \(previous.reps)"
    }

    private var weightBinding: Binding<Double> {
        Binding(
            get: { unit.display(set.weight) },
            set: { set.weight = unit.toKilograms($0) }
        )
    }

    private var repsBinding: Binding<Double> {
        Binding(
            get: { Double(set.reps) },
            set: { set.reps = max(0, Int($0)) }
        )
    }

    private func fillFromPrevious() {
        guard let previous else { return }
        set.weight = previous.weight
        set.reps = previous.reps
    }

    private func toggleDone() {
        if set.isDone {
            set.isDone = false
            return
        }
        if set.reps == 0, previous != nil {
            fillFromPrevious()
        }
        set.isDone = true
        onCompleted()
    }
}

/// A text field that writes a number back on every keystroke, so values are
/// saved even if the user taps a checkmark without dismissing the keyboard.
struct NumberField: View {
    @Binding var value: Double
    let allowsDecimal: Bool

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField("0", text: $text)
            .keyboardType(allowsDecimal ? .decimalPad : .numberPad)
            .multilineTextAlignment(.center)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
            .focused($focused)
            .onAppear { text = Self.format(value) }
            .onChange(of: text) { _, newText in
                if newText.isEmpty {
                    value = 0
                } else if let parsed = Self.parse(newText) {
                    value = parsed
                }
            }
            .onChange(of: value) { _, newValue in
                if !focused { text = Self.format(newValue) }
            }
    }

    static func parse(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    static func format(_ value: Double) -> String {
        guard value != 0 else { return "" }
        let rounded = (value * 100).rounded() / 100
        return rounded == rounded.rounded()
            ? String(Int(rounded))
            : String(rounded)
    }
}
