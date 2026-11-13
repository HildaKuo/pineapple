import Foundation
import SwiftData

// MARK: - Enums

enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core, fullBody

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }
}

enum Equipment: String, CaseIterable, Identifiable {
    case barbell, dumbbell, machine, cable, bodyweight, kettlebell, band, other

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

// MARK: - Exercise

@Model
final class Exercise {
    var name: String
    var muscleRaw: String
    var equipmentRaw: String
    var isCustom: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \WorkoutExercise.exercise)
    var workoutEntries: [WorkoutExercise] = []

    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.exercise)
    var routineItems: [RoutineItem] = []

    init(name: String, muscle: MuscleGroup, equipment: Equipment, isCustom: Bool = false) {
        self.name = name
        self.muscleRaw = muscle.rawValue
        self.equipmentRaw = equipment.rawValue
        self.isCustom = isCustom
        self.createdAt = .now
    }

    var muscle: MuscleGroup { MuscleGroup(rawValue: muscleRaw) ?? .fullBody }
    var equipment: Equipment { Equipment(rawValue: equipmentRaw) ?? .other }
    var subtitle: String { "\(muscle.title) · \(equipment.title)" }
}

// MARK: - Workout

@Model
final class Workout {
    var name: String
    var startedAt: Date
    var endedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var entries: [WorkoutExercise] = []

    init(name: String, startedAt: Date = .now) {
        self.name = name
        self.startedAt = startedAt
    }

    var sortedEntries: [WorkoutExercise] { entries.sorted { $0.order < $1.order } }
    var duration: TimeInterval { (endedAt ?? .now).timeIntervalSince(startedAt) }
    var completedSets: [WorkoutSet] { entries.flatMap { $0.sets }.filter { $0.isDone } }
    var volume: Double { completedSets.reduce(0) { $0 + $1.volume } }
}

@Model
final class WorkoutExercise {
    var order: Int
    var exercise: Exercise?
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.entry)
    var sets: [WorkoutSet] = []

    init(order: Int) {
        self.order = order
    }

    var sortedSets: [WorkoutSet] { sets.sorted { $0.order < $1.order } }
}

@Model
final class WorkoutSet {
    var order: Int
    /// Always stored in kilograms. Convert with `WeightUnit` for display.
    var weight: Double
    var reps: Int
    var isDone: Bool
    var entry: WorkoutExercise?

    init(order: Int, weight: Double = 0, reps: Int = 0) {
        self.order = order
        self.weight = weight
        self.reps = reps
        self.isDone = false
    }

    var volume: Double { weight * Double(reps) }

    /// Epley formula.
    var estimatedOneRepMax: Double {
        guard reps > 0 else { return 0 }
        return reps == 1 ? weight : weight * (1 + Double(reps) / 30)
    }
}

// MARK: - Routine

@Model
final class Routine {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.routine)
    var items: [RoutineItem] = []

    init(name: String) {
        self.name = name
        self.createdAt = .now
    }

    var sortedItems: [RoutineItem] { items.sorted { $0.order < $1.order } }
    var summary: String {
        let names = sortedItems.compactMap { $0.exercise?.name }
        return names.isEmpty ? "No exercises" : names.joined(separator: ", ")
    }
}

@Model
final class RoutineItem {
    var order: Int
    var setCount: Int
    var exercise: Exercise?
    var routine: Routine?

    init(order: Int, setCount: Int = 3) {
        self.order = order
        self.setCount = setCount
    }
}

// MARK: - Progress helpers

struct ExerciseSession: Identifiable {
    let id: PersistentIdentifier
    let date: Date
    let sets: [WorkoutSet]

    var heaviest: Double { sets.map(\.weight).max() ?? 0 }
    var bestEstimatedMax: Double { sets.map(\.estimatedOneRepMax).max() ?? 0 }
    var volume: Double { sets.reduce(0) { $0 + $1.volume } }
    var mostReps: Int { sets.map(\.reps).max() ?? 0 }
}

extension Exercise {
    /// Completed sets from finished workouts, oldest first.
    var sessions: [ExerciseSession] {
        workoutEntries
            .compactMap { entry -> ExerciseSession? in
                guard let workout = entry.workout, workout.endedAt != nil else { return nil }
                let done = entry.sortedSets.filter(\.isDone)
                guard !done.isEmpty else { return nil }
                return ExerciseSession(id: entry.persistentModelID, date: workout.startedAt, sets: done)
            }
            .sorted { $0.date < $1.date }
    }

    /// Sets from the most recent finished workout that included this exercise.
    var lastCompletedSets: [WorkoutSet] { sessions.last?.sets ?? [] }
}

// MARK: - Builders

enum WorkoutBuilder {
    static func addExercise(_ exercise: Exercise, sets count: Int, to workout: Workout, in context: ModelContext) {
        let entry = WorkoutExercise(order: (workout.entries.map(\.order).max() ?? -1) + 1)
        context.insert(entry)
        entry.exercise = exercise
        entry.workout = workout

        let previous = exercise.lastCompletedSets
        for index in 0..<max(count, 1) {
            let source = index < previous.count ? previous[index] : previous.last
            addSet(to: entry, weight: source?.weight ?? 0, reps: source?.reps ?? 0, in: context)
        }
    }

    static func addSet(to entry: WorkoutExercise, weight: Double, reps: Int, in context: ModelContext) {
        let set = WorkoutSet(order: (entry.sets.map(\.order).max() ?? -1) + 1, weight: weight, reps: reps)
        context.insert(set)
        set.entry = entry
    }

    static func start(from routine: Routine?, name: String, in context: ModelContext) -> Workout {
        let workout = Workout(name: name)
        context.insert(workout)
        for item in routine?.sortedItems ?? [] {
            guard let exercise = item.exercise else { continue }
            addExercise(exercise, sets: item.setCount, to: workout, in: context)
        }
        return workout
    }

    static func defaultName(for date: Date = .now) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: return "Morning Workout"
        case 12..<17: return "Afternoon Workout"
        default: return "Evening Workout"
        }
    }
}
