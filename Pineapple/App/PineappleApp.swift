import SwiftData
import SwiftUI

@main
struct PineappleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            Exercise.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            Routine.self,
            RoutineItem.self,
        ])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            WorkoutTab()
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .task {
            ExerciseSeed.insertIfNeeded(into: context)
        }
    }
}
