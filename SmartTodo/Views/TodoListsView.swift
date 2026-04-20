import SwiftUI
import SwiftData

struct TodoListsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\TodoList.createdAt, order: .reverse)])
    private var lists: [TodoList]

    @State private var showAddSheet = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    EmptyStateView {
                        showAddSheet = true
                    }
                } else {
                    List {
                        ForEach(lists) { list in
                            NavigationLink(value: list) {
                                TodoListRow(list: list)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("清单")
            .navigationDestination(for: TodoList.self) { list in
                TodoDetailView(list: list)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTodoView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .tint(.primary)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(lists[index])
        }
        try? context.save()
    }
}

private struct TodoListRow: View {
    let list: TodoList

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(list.title)
                .font(.headline)
                .lineLimit(1)
            Text(list.goal)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
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
}

private struct EmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text("还没有清单")
                .font(.title3.weight(.semibold))
            Text("写下一件你想完成的事，\nAI 会帮你拆成可执行的步骤。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onAdd) {
                Label("新建清单", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.primary, in: Capsule())
                    .foregroundStyle(Color(.systemBackground))
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    TodoListsView()
        .modelContainer(for: [TodoList.self, TodoItem.self], inMemory: true)
}
