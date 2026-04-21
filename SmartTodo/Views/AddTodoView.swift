import SwiftUI
import SwiftData

struct AddTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var viewModel = TodoListViewModel()
    @State private var goal: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("想做什么？")
                    .font(.title2.weight(.semibold))
                    .padding(.top, 8)

                Text("描述一件你想完成的事，AI 会帮你拆成可执行的清单。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    if goal.isEmpty {
                        Text("例如：周末和朋友去露营")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 14)
                            .padding(.horizontal, 14)
                    }
                    TextEditor(text: $goal)
                        .focused($focused)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                }
                .frame(minHeight: 140)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                Spacer(minLength: 0)

                if case .error(let msg) = viewModel.state {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                }

                Button(action: submit) {
                    HStack {
                        if case .generating = viewModel.state {
                            ProgressView()
                                .tint(Color(.systemBackground))
                            Text("生成中…")
                        } else {
                            Image(systemName: "sparkles")
                            Text("生成清单")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        (goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                         ? Color.secondary : Color.primary),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .foregroundStyle(Color(.systemBackground))
                }
                .disabled(goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.state == .generating)
            }
            .padding()
            .navigationTitle("新建清单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }

    private func submit() {
        Task {
            if let _ = await viewModel.generate(goal: goal, into: context) {
                dismiss()
            }
        }
    }
}

#Preview {
    AddTodoView()
        .modelContainer(for: [TodoList.self, TodoItem.self], inMemory: true)
}
