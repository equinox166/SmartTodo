import Foundation
import SwiftData

@MainActor
@Observable
final class TodoListViewModel {
    enum State: Equatable {
        case idle
        case generating
        case error(String)
    }

    var state: State = .idle
    private let client = DeepSeekClient()

    func generate(goal: String, into context: ModelContext) async -> TodoList? {
        let trimmed = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        state = .generating
        defer { if case .generating = state { state = .idle } }

        do {
            let result = try await client.generateChecklist(goal: trimmed)
            let list = TodoList(title: result.title.isEmpty ? trimmed : result.title, goal: trimmed)
            context.insert(list)
            for (index, item) in result.items.enumerated() {
                let todo = TodoItem(title: item.title, detail: item.detail, order: index)
                todo.list = list
                context.insert(todo)
            }
            try context.save()
            state = .idle
            return list
        } catch {
            state = .error(error.localizedDescription)
            return nil
        }
    }

    func delete(_ list: TodoList, context: ModelContext) {
        context.delete(list)
        try? context.save()
    }

    func toggle(_ item: TodoItem, context: ModelContext) {
        item.isDone.toggle()
        try? context.save()
    }
}
