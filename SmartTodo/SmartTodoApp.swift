import SwiftUI
import SwiftData

@main
struct SmartTodoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([TodoList.self, TodoItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TodoListsView()
        }
        .modelContainer(sharedModelContainer)
    }
}
