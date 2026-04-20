import Foundation
import SwiftData

@Model
final class TodoList {
    var id: UUID
    var title: String
    var goal: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TodoItem.list)
    var items: [TodoItem] = []

    init(id: UUID = UUID(), title: String, goal: String, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.goal = goal
        self.createdAt = createdAt
    }

    var completedCount: Int {
        items.filter { $0.isDone }.count
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(completedCount) / Double(items.count)
    }
}

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var detail: String
    var isDone: Bool
    var order: Int
    var createdAt: Date
    var list: TodoList?

    init(id: UUID = UUID(),
         title: String,
         detail: String = "",
         isDone: Bool = false,
         order: Int = 0,
         createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isDone = isDone
        self.order = order
        self.createdAt = createdAt
    }
}
