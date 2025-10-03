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
- 📥 专门的上传和下载脚本，操作更清晰
- 🔄 智能扩展同步，支持覆盖模式和扩展模式

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
├── update-config.sh           # 更新脚本 (管理员用，兼容旧版本)
├── upload-config.sh           # 上传脚本 (管理员用，推荐)
├── download-config.sh         # 下载脚本 (团队成员用)
├── sync-extensions.sh         # 扩展同步脚本
├── upload.sh                  # 快速上传脚本 (管理员用)
├── download.sh                # 快速下载脚本 (覆盖模式)
├── download-extend.sh         # 快速下载脚本 (扩展模式)
├── sync.sh                    # 快速同步脚本 (覆盖模式)
├── sync-extend.sh             # 快速同步脚本 (扩展模式)
└── README.md                  # 说明文档
```

## 🚀 使用方法

### 基本使用

1. **克隆仓库:**
   ```bash
   git clone <仓库URL> vscode-config
   cd vscode-config
   ```

2. **给脚本执行权限:**
   ```bash
   chmod +x *.sh
   ```

3. **团队成员下载配置:**
   ```bash
   # 下载并安装配置（覆盖模式）
   ./download.sh
   
   # 下载并安装配置（扩展模式）
   ./download-extend.sh
   ```

4. **管理员上传配置:**
   ```bash
   # 上传本地配置
   ./upload.sh
   ```

### 高级用法

#### 下载配置

```bash
# 交互式下载
./download-config.sh

# 自动下载最新配置
./download-config.sh --auto-pull --force

# 下载并清理本地未跟踪文件
./download-config.sh --auto-pull --clean --force

# 使用扩展模式（不卸载任何扩展）
./download-config.sh --auto-pull --force --mode extend
```

#### 安装配置

```bash
# 交互式安装
./setup.sh

# 静默安装
./setup.sh --force --silent

# 使用扩展模式
./setup.sh --force --silent --mode extend
```

#### 上传配置

```bash
# 交互式上传
./upload-config.sh

# 自动提交并推送
./upload-config.sh --auto-commit --auto-push --force

# 上传前先同步远程更改
./upload-config.sh --auto-commit --auto-push --force --sync-before

# 推送到多个远程仓库
./upload-config.sh --auto-commit --auto-push --force --push-remotes origin,gitee
```

#### 同步扩展

```bash
# 交互式同步（覆盖模式）
./sync-extensions.sh

# 强制同步（覆盖模式）
./sync-extensions.sh --force

# 扩展模式（不卸载任何扩展）
./sync-extensions.sh --force --mode extend

# 仅同步扩展（覆盖模式）
./sync.sh

# 仅同步扩展（扩展模式）
./sync-extend.sh
```

### 同步模式说明

- **覆盖模式 (overwrite)**：安装列表中的扩展，卸载不在列表中的扩展。确保所有团队成员的扩展列表完全一致。
- **扩展模式 (extend)**：只安装列表中缺失的扩展，不卸载任何扩展。适合希望保留个人扩展同时获取团队标准扩展的场景。

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
# 使用完整脚本的别名
alias install-vscode='cd /path/to/vscode-config && ./setup.sh --force --silent'
alias download-vscode='cd /path/to/vscode-config && ./download-config.sh --auto-pull --force && ./setup.sh --force --silent'
alias download-vscode-extend='cd /path/to/vscode-config && ./download-config.sh --auto-pull --force --mode extend && ./setup.sh --force --silent --mode extend'
alias upload-vscode='cd /path/to/vscode-config && ./upload-config.sh --auto-commit --auto-push --force --push-remotes origin,gitee'
alias sync-extensions='cd /path/to/vscode-config && ./sync-extensions.sh --force'
alias sync-extensions-extend='cd /path/to/vscode-config && ./sync-extensions.sh --force --mode extend'

# 使用快速脚本的别名（推荐）
alias vs-upload='cd /path/to/vscode-config && ./upload.sh'
alias vs-download='cd /path/to/vscode-config && ./download.sh'
alias vs-download-extend='cd /path/to/vscode-config && ./download-extend.sh'
alias vs-sync='cd /path/to/vscode-config && ./sync.sh'
alias vs-sync-extend='cd /path/to/vscode-config && ./sync-extend.sh'

# 使用
# 完整脚本版本
install-vscode           # 安装配置（覆盖模式）
download-vscode          # 下载并安装最新配置（覆盖模式）
download-vscode-extend   # 下载并安装最新配置（扩展模式）
upload-vscode            # 上传本地配置
sync-extensions          # 仅同步扩展（覆盖模式）
sync-extensions-extend   # 仅同步扩展（扩展模式）

# 快速脚本版本（推荐）
vs-upload                # 一键上传配置
vs-download              # 一键下载并安装配置（覆盖模式）
vs-download-extend       # 一键下载并安装配置（扩展模式）
vs-sync                  # 一键同步扩展（覆盖模式）
vs-sync-extend           # 一键同步扩展（扩展模式）
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
- 🔄 建议定期运行下载脚本以获取最新的团队配置更新
- 🌐 网络问题可能导致扩展安装失败，脚本支持重新运行
- 🔄 使用上传脚本前，建议先使用 `--sync-before` 选项同步远程更改，避免冲突
- 🔄 覆盖模式会自动卸载不在列表中的扩展，确保所有团队成员的扩展列表完全一致
- 🔄 扩展模式只安装缺失的扩展，不卸载任何扩展，适合需要保留个人扩展的场景
- 🔄 团队应统一使用一种同步模式，避免扩展同步混乱

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

### Q: 为什么一台电脑删除的扩展，在另一台电脑上还存在？

A: 这是因为旧版本的脚本只负责安装扩展，不负责卸载不在列表中的扩展。新版本已解决此问题：
1. 使用新的下载脚本：`./download-config.sh --auto-pull --force`
2. 或者单独运行扩展同步脚本：`./sync-extensions.sh --force`
3. 这将自动卸载不在extensions.list中的扩展

### Q: 如何只同步扩展而不更新其他配置？

A: 使用扩展同步脚本：
```bash
# 交互式同步（覆盖模式）
./sync-extensions.sh

# 强制同步，自动安装和卸载（覆盖模式）
./sync-extensions.sh --force

# 扩展模式：只安装新扩展，不卸载任何扩展
./sync-extensions.sh --force --mode extend
```

### Q: 覆盖模式和扩展模式有什么区别？

A: 两种模式的区别如下：
- **覆盖模式 (overwrite)**：安装列表中的所有扩展，同时卸载不在列表中的扩展。这确保所有团队成员的VSCode环境完全一致，适合需要标准化开发环境的团队。
- **扩展模式 (extend)**：只安装列表中缺失的扩展，不卸载任何扩展。适合希望保留个人扩展同时获取团队标准扩展的场景，提供更大的灵活性。

使用示例：
```bash
# 下载配置并使用覆盖模式同步扩展（默认）
./download-config.sh --auto-pull --force --mode overwrite

# 下载配置并使用扩展模式同步扩展
./download-config.sh --auto-pull --force --mode extend

# 安装配置并使用覆盖模式同步扩展（默认）
./setup.sh --force --silent --mode overwrite

# 安装配置并使用扩展模式同步扩展
./setup.sh --force --silent --mode extend
```

## 📞 技术支持

如遇到问题，请：
1. 查看脚本输出的错误信息
2. 检查 VSCode 和 Git 是否正确安装
3. 确认网络连接正常
4. 联系仓库管理员

---

🎉 **享受统一的 VSCode 开发体验！**