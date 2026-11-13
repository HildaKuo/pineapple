import SwiftData
import SwiftUI

struct RoutineEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var routine: Routine
    @State private var showingPicker = false

    var body: some View {
        List {
            Section("Name") {
                TextField("Routine name", text: $routine.name)
            }

            Section("Exercises") {
                ForEach(routine.sortedItems) { item in
                    RoutineItemRow(item: item)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)

                Button {
                    showingPicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .navigationTitle(routine.name.isEmpty ? "Routine" : routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                let item = RoutineItem(order: (routine.items.map(\.order).max() ?? -1) + 1)
                context.insert(item)
                item.exercise = exercise
                item.routine = routine
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let items = routine.sortedItems
        for index in offsets {
            let item = items[index]
            routine.items.removeAll { $0.persistentModelID == item.persistentModelID }
            context.delete(item)
        }
        renumber(routine.sortedItems)
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var items = routine.sortedItems
        items.move(fromOffsets: source, toOffset: destination)
        renumber(items)
    }

    private func renumber(_ items: [RoutineItem]) {
        for (index, item) in items.enumerated() {
            item.order = index
        }
    }
}

struct RoutineItemRow: View {
    @Bindable var item: RoutineItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.exercise?.name ?? "Deleted exercise")
                if let exercise = item.exercise {
                    Text(exercise.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Stepper("\(item.setCount) sets", value: $item.setCount, in: 1...10)
                .fixedSize()
                .font(.subheadline)
        }
    }
}
