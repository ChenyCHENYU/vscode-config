# VSCode 团队配置管理

这个仓库用于管理和分发 VSCode 的标准配置，包括设置、快捷键、代码片段和扩展列表。支持跨平台使用，提供自动化的安装和更新工具。

## ✨ 特性

- 🔄 集中管理 VSCode 配置
- 👥 团队成员可以轻松下载和应用标准配置
- 🔒 仅管理员可以更新配置
- 🌍 支持 Windows、macOS 和 Linux 系统
- 🚀 自动安装所需扩展
- 💾 自动备份现有配置
- ⚡ 防卡死设计，支持超时控制
- 🎨 美化的Git状态显示和进度反馈
- 🔧 支持静默模式和强制模式

## 📁 目录结构

```
.
├── settings.json              # VSCode 用户设置
├── keybindings.json           # VSCode 快捷键配置
├── extensions.list            # 扩展列表
├── snippets/                  # 代码片段配置
│   ├── doc.code-snippets      # 文档代码片段
│   ├── vue-directives.json    # Vue 指令代码片段
│   └── vue.json               # Vue 代码片段
├── setup.sh                   # 安装脚本
├── update-config.sh           # 更新脚本 (管理员用)
└── README.md                  # 说明文档
```

## 🚀 使用方法

### 👨‍💻 团队成员 - 安装配置

1. **克隆仓库:**
   ```bash
   git clone <仓库URL> vscode-config
   cd vscode-config
   ```

2. **给脚本执行权限:**
   ```bash
   chmod +x setup.sh
   ```

3. **运行安装脚本:**
   ```bash
   # 交互式安装
   ./setup.sh
   
   # 静默安装 (推荐)
   ./setup.sh --force --silent
   
   # 自定义超时时间
   ./setup.sh --timeout 60
   ```

#### 📋 安装选项

| 参数 | 说明 |
|------|------|
| `--force` | 强制安装，无交互确认 |
| `--silent` | 静默模式，不等待用户输入 |
| `--timeout N` | 扩展安装超时时间(秒，默认30) |
| `--help` | 显示帮助信息 |

### 🔧 管理员 - 更新配置

#### 一键自动化更新 (推荐)

```bash
# 完全自动化：更新配置 → 提交 → 推送到多个远程仓库
./update-config.sh --auto-commit --auto-push --force --push-remotes origin,gitee

# 自定义提交消息
./update-config.sh --auto-commit --auto-push --commit-message "重要配置更新" --push-remotes origin,gitee
```

#### 交互式更新

```bash
# 切换到配置仓库目录
cd /path/to/vscode-config

# 运行更新脚本
./update-config.sh

# 按提示选择是否提交和推送
```

#### 🎛️ 更新选项

| 参数 | 说明 |
|------|------|
| `--auto-commit` | 自动提交更改 |
| `--auto-push` | 自动推送到远程仓库 |
| `--force` | 强制执行，无交互确认 |
| `--commit-message "MSG"` | 自定义提交消息 |
| `--push-remotes origin,gitee` | 指定推送的远程仓库 |
| `--help` | 显示帮助信息 |

## 🎨 美化的状态显示

更新脚本提供了优雅的Git状态显示：

```
📋 检测到以下更改:
────────────────────────────────────────
📝 修改 settings.json (+8/-2)
📝 修改 keybindings.json (+5)
📄 新增 snippets/vue.json (67 行)
🗑️ 删除 old-config.json
────────────────────────────────────────
📊 更改统计: 新增 1 修改 2 删除 1 (共 4 个文件)
```

## 🛡️ 安全特性

- **自动备份**: 安装前自动备份现有配置到带时间戳的目录
- **超时控制**: 扩展安装支持超时，防止脚本卡死
- **错误处理**: 完善的错误检查和友好的错误提示
- **恢复机制**: 提供清晰的配置恢复命令

## 📚 常用命令

### 🔄 创建便捷别名

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
alias install-vscode='cd /path/to/vscode-config && ./setup.sh --force --silent'
alias update-vscode='cd /path/to/vscode-config && ./update-config.sh --auto-commit --auto-push --force --push-remotes origin,gitee'

# 使用
install-vscode  # 安装配置
update-vscode   # 更新配置
```

### 🔙 恢复备份配置

如果需要恢复之前的配置：

```bash
# 查看备份目录
ls ~/.config/Code/User/backup_*

# 恢复指定备份 (Linux/macOS)
cp -r ~/.config/Code/User/backup_20250730143052/* ~/.config/Code/User/

# 恢复指定备份 (Windows)
Copy-Item "C:\Users\用户名\AppData\Roaming\Code\User\backup_20250730143052\*" "C:\Users\用户名\AppData\Roaming\Code\User\" -Recurse -Force
```

## ⚙️ 系统要求

- **VSCode**: 已安装并添加到 PATH
- **Git**: 用于克隆仓库和版本控制
- **Bash**: Linux/macOS 自带，Windows 可使用 Git Bash

## 🔐 权限管理

- 将仓库设置为私有仓库
- 团队成员设置为只读权限 (Reporter/Reader 角色)
- 仅管理员拥有写入权限 (Maintainer/Writer 角色)

## ⚠️ 注意事项

- 📦 安装脚本会覆盖现有的 VSCode 配置，脚本会自动备份
- 🎯 如果团队成员需要个性化设置，建议在团队配置基础上进行调整
- 🔌 某些扩展可能需要额外的配置或登录，请参考相应扩展的文档
- 🔄 建议定期运行安装脚本以获取最新的团队配置更新
- 🌐 网络问题可能导致扩展安装失败，脚本支持重新运行

## 🆘 常见问题

### Q: 脚本执行时卡住了怎么办？

A: 新版本脚本已解决卡死问题。如遇到问题：
1. 按 `Ctrl+C` 终止脚本
2. 使用 `--timeout 60` 增加超时时间
3. 使用 `--silent --force` 静默模式

### Q: 扩展安装失败怎么办？

A: 脚本会显示失败的扩展和原因：
1. 检查网络连接
2. 手动安装失败的扩展：`code --install-extension 扩展名`
3. 重新运行安装脚本

### Q: 如何同步到多个Git仓库？

A: 使用更新脚本的多仓库推送功能：
```bash
./update-config.sh --auto-commit --auto-push --push-remotes origin,gitee,gitlab
```

## 📞 技术支持

如遇到问题，请：
1. 查看脚本输出的错误信息
2. 检查 VSCode 和 Git 是否正确安装
3. 确认网络连接正常
4. 联系仓库管理员

---

🎉 **享受统一的 VSCode 开发体验！**