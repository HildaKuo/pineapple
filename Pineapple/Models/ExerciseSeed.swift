import Foundation
import SwiftData

enum ExerciseSeed {
    static func insertIfNeeded(into context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        guard count == 0 else { return }
        for (name, muscle, equipment) in all {
            context.insert(Exercise(name: name, muscle: muscle, equipment: equipment))
        }
        try? context.save()
    }

    static let all: [(String, MuscleGroup, Equipment)] = [
        // Chest
        ("Bench Press", .chest, .barbell),
        ("Incline Bench Press", .chest, .barbell),
        ("Decline Bench Press", .chest, .barbell),
        ("Dumbbell Bench Press", .chest, .dumbbell),
        ("Incline Dumbbell Press", .chest, .dumbbell),
        ("Dumbbell Fly", .chest, .dumbbell),
        ("Cable Crossover", .chest, .cable),
        ("Chest Press Machine", .chest, .machine),
        ("Pec Deck", .chest, .machine),
        ("Push-Up", .chest, .bodyweight),
        ("Chest Dip", .chest, .bodyweight),
        // Back
        ("Deadlift", .back, .barbell),
        ("Barbell Row", .back, .barbell),
        ("Pendlay Row", .back, .barbell),
        ("T-Bar Row", .back, .barbell),
        ("Dumbbell Row", .back, .dumbbell),
        ("Pull-Up", .back, .bodyweight),
        ("Chin-Up", .back, .bodyweight),
        ("Lat Pulldown", .back, .cable),
        ("Seated Cable Row", .back, .cable),
        ("Straight-Arm Pulldown", .back, .cable),
        ("Machine Row", .back, .machine),
        ("Back Extension", .back, .bodyweight),
        // Shoulders
        ("Overhead Press", .shoulders, .barbell),
        ("Push Press", .shoulders, .barbell),
        ("Seated Dumbbell Press", .shoulders, .dumbbell),
        ("Arnold Press", .shoulders, .dumbbell),
        ("Lateral Raise", .shoulders, .dumbbell),
        ("Front Raise", .shoulders, .dumbbell),
        ("Rear Delt Fly", .shoulders, .dumbbell),
        ("Cable Lateral Raise", .shoulders, .cable),
        ("Face Pull", .shoulders, .cable),
        ("Shoulder Press Machine", .shoulders, .machine),
        ("Upright Row", .shoulders, .barbell),
        ("Barbell Shrug", .shoulders, .barbell),
        ("Dumbbell Shrug", .shoulders, .dumbbell),
        // Biceps
        ("Barbell Curl", .biceps, .barbell),
        ("EZ-Bar Curl", .biceps, .barbell),
        ("Dumbbell Curl", .biceps, .dumbbell),
        ("Hammer Curl", .biceps, .dumbbell),
        ("Incline Dumbbell Curl", .biceps, .dumbbell),
        ("Concentration Curl", .biceps, .dumbbell),
        ("Preacher Curl", .biceps, .machine),
        ("Cable Curl", .biceps, .cable),
        // Triceps
        ("Close-Grip Bench Press", .triceps, .barbell),
        ("Skull Crusher", .triceps, .barbell),
        ("Triceps Pushdown", .triceps, .cable),
        ("Rope Pushdown", .triceps, .cable),
        ("Overhead Cable Extension", .triceps, .cable),
        ("Overhead Dumbbell Extension", .triceps, .dumbbell),
        ("Dumbbell Kickback", .triceps, .dumbbell),
        ("Bench Dip", .triceps, .bodyweight),
        // Quads
        ("Back Squat", .quads, .barbell),
        ("Front Squat", .quads, .barbell),
        ("Goblet Squat", .quads, .dumbbell),
        ("Bulgarian Split Squat", .quads, .dumbbell),
        ("Walking Lunge", .quads, .dumbbell),
        ("Leg Press", .quads, .machine),
        ("Hack Squat", .quads, .machine),
        ("Leg Extension", .quads, .machine),
        ("Step-Up", .quads, .dumbbell),
        // Hamstrings
        ("Romanian Deadlift", .hamstrings, .barbell),
        ("Stiff-Leg Deadlift", .hamstrings, .barbell),
        ("Dumbbell Romanian Deadlift", .hamstrings, .dumbbell),
        ("Good Morning", .hamstrings, .barbell),
        ("Lying Leg Curl", .hamstrings, .machine),
        ("Seated Leg Curl", .hamstrings, .machine),
        ("Nordic Curl", .hamstrings, .bodyweight),
        // Glutes
        ("Hip Thrust", .glutes, .barbell),
        ("Glute Bridge", .glutes, .bodyweight),
        ("Cable Kickback", .glutes, .cable),
        ("Hip Abduction Machine", .glutes, .machine),
        ("Sumo Deadlift", .glutes, .barbell),
        // Calves
        ("Standing Calf Raise", .calves, .machine),
        ("Seated Calf Raise", .calves, .machine),
        ("Dumbbell Calf Raise", .calves, .dumbbell),
        // Core
        ("Plank", .core, .bodyweight),
        ("Crunch", .core, .bodyweight),
        ("Hanging Leg Raise", .core, .bodyweight),
        ("Cable Crunch", .core, .cable),
        ("Ab Wheel Rollout", .core, .other),
        ("Russian Twist", .core, .bodyweight),
        ("Pallof Press", .core, .cable),
        // Full body
        ("Power Clean", .fullBody, .barbell),
        ("Kettlebell Swing", .fullBody, .kettlebell),
        ("Farmer's Carry", .fullBody, .dumbbell),
        ("Thruster", .fullBody, .barbell),
        ("Turkish Get-Up", .fullBody, .kettlebell),
        ("Burpee", .fullBody, .bodyweight),
    ]
}
