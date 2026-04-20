import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-…", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("DeepSeek API Key")
                } footer: {
                    Text("API Key 仅保存在本机 Keychain，不会上传任何服务器。没有 Key？前往 platform.deepseek.com 申请。")
                }

                Section {
                    Button {
                        KeychainHelper.save(apiKey, for: SecretKeys.deepSeekAPIKey)
                        showSaved = true
                    } label: {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button(role: .destructive) {
                        KeychainHelper.delete(SecretKeys.deepSeekAPIKey)
                        apiKey = ""
                    } label: {
                        Text("清除 API Key")
                            .frame(maxWidth: .infinity)
                    }
                }

                Section {
                    LabeledContent("版本", value: Bundle.main.shortVersion)
                    Link("DeepSeek 控制台",
                         destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                apiKey = KeychainHelper.read(SecretKeys.deepSeekAPIKey) ?? ""
            }
            .alert("已保存", isPresented: $showSaved) {
                Button("好") {}
            }
        }
    }
}

private extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}

#Preview {
    SettingsView()
}
