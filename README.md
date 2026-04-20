# SmartTodo

极简风格的 iOS Todo List app。用户写下想完成的一件事，**DeepSeek** 会把它拆成可执行的详细清单。

- SwiftUI + SwiftData（iOS 17+）
- MVVM 结构
- 本地 Keychain 保存 API Key，不上传任何服务器
- 黑白极简 UI

## 运行

1. 克隆仓库到本地（需要 macOS + Xcode 15 或更高版本）。
2. 直接打开 `SmartTodo.xcodeproj`。
3. 选中一个 iOS 17+ 的模拟器或真机，按 **⌘R** 运行。
4. 首次启动，点左上角 ⚙️ 进入设置页，粘贴你的 DeepSeek API Key（在 <https://platform.deepseek.com/api_keys> 申请）。
5. 回到主页，点右上角 `+`，输入一件想做的事（例如"周末和朋友去露营"），AI 会生成详细清单。

## 工程结构

```
SmartTodo/
├── SmartTodoApp.swift            # @main 入口
├── Models/
│   └── TodoModels.swift          # SwiftData 数据模型
├── Services/
│   ├── DeepSeekClient.swift      # DeepSeek Chat API 调用（JSON 返回）
│   └── KeychainHelper.swift      # Keychain 读写
├── ViewModels/
│   └── TodoListViewModel.swift   # 生成清单、勾选、删除
├── Views/
│   ├── TodoListsView.swift       # 主列表
│   ├── AddTodoView.swift         # 新建清单（输入 + 生成）
│   ├── TodoDetailView.swift      # 清单详情 + 勾选/添加子项
│   └── SettingsView.swift        # API Key 配置
├── Resources/Info.plist
├── Assets.xcassets
└── Preview Content/
```

## 重新生成 Xcode 工程

`SmartTodo.xcodeproj` 是通过 `scripts/generate_xcodeproj.rb` 脚本从源码生成的。
当你新增/删除/重命名源码文件后，重新生成一次即可：

```bash
gem install xcodeproj   # 只需一次
ruby scripts/generate_xcodeproj.rb
```

## API 契约

DeepSeek 系统 prompt 要求模型返回严格的 JSON：

```json
{
  "title": "清单标题",
  "items": [
    { "title": "步骤标题", "detail": "简短说明" }
  ]
}
```

调用 `https://api.deepseek.com/chat/completions`，`model = deepseek-chat`，`response_format = { type: "json_object" }`，`temperature = 0.3`。

## 已知限制

- Xcode 工程在 Linux 上生成，未经真机/模拟器编译验证。若首次打开 Xcode 报错，通常是签名或 iOS 部署目标相关，按提示选择 team / 调整 iOS 版本即可。
