import SwiftData
import SwiftUI

/// Shows the active workout if there is one, otherwise the start screen.
struct WorkoutTab: View {
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }, sort: \Workout.startedAt)
    private var activeWorkouts: [Workout]

    var body: some View {
        NavigationStack {
            if let workout = activeWorkouts.first {
                ActiveWorkoutView(workout: workout)
            } else {
                StartWorkoutView()
            }
        }
    }
}

struct StartWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @State private var editingRoutine: Routine?

    var body: some View {
        List {
            Section {
                Button {
                    _ = WorkoutBuilder.start(from: nil, name: WorkoutBuilder.defaultName(), in: context)
                } label: {
                    Label("Start Empty Workout", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }

            Section("Routines") {
                if routines.isEmpty {
                    Text("Save a routine to start the same workout again with one tap.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                ForEach(routines) { routine in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name).font(.headline)
                            Text(routine.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture { editingRoutine = routine }

                        Button("Start") {
                            _ = WorkoutBuilder.start(from: routine, name: routine.name, in: context)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(routine.items.isEmpty)
                    }
                    .swipeActions(edge: .leading) {
                        Button("Edit") { editingRoutine = routine }.tint(.blue)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(routines[index]) }
                }

                Button {
                    let routine = Routine(name: "New Routine")
                    context.insert(routine)
                    editingRoutine = routine
                } label: {
                    Label("New Routine", systemImage: "square.and.pencil")
                }
            }
        }
        .navigationTitle("Workout")
        .navigationDestination(item: $editingRoutine) { routine in
            RoutineEditorView(routine: routine)
        }
    }
}
