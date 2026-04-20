import SwiftUI
import SwiftData

struct TodoDetailView: View {
    @Bindable var list: TodoList
    @Environment(\.modelContext) private var context
    @State private var newItemTitle: String = ""
    @FocusState private var addFocused: Bool

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(list.goal)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ProgressView(value: list.progress)
                            .progressViewStyle(.linear)
                            .tint(.primary)
                        Text("\(list.completedCount)/\(list.items.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                ForEach(sortedItems) { item in
                    ItemRow(item: item) {
                        toggle(item)
                    }
                }
                .onDelete(perform: deleteItems)

                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.secondary)
                    TextField("添加一项", text: $newItemTitle)
                        .focused($addFocused)
                        .submitLabel(.done)
                        .onSubmit(addItem)
                }
            } header: {
                Text("任务")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(list.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedItems: [TodoItem] {
        list.items.sorted { $0.order < $1.order }
    }

    private func toggle(_ item: TodoItem) {
        item.isDone.toggle()
        try? context.save()
    }

    private func deleteItems(at offsets: IndexSet) {
        let items = sortedItems
        for index in offsets {
            context.delete(items[index])
        }
        try? context.save()
    }

    private func addItem() {
        let text = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let nextOrder = (list.items.map(\.order).max() ?? -1) + 1
        let item = TodoItem(title: text, order: nextOrder)
        item.list = list
        context.insert(item)
        try? context.save()
        newItemTitle = ""
    }
}

private struct ItemRow: View {
    @Bindable var item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isDone ? Color.primary : Color.secondary)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                        .strikethrough(item.isDone, color: .secondary)
                        .foregroundStyle(item.isDone ? .secondary : .primary)
                    if !item.detail.isEmpty {
                        Text(item.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
