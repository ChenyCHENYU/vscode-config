# VSCode 团队配置管理

这个仓库用于管理和分发 VSCode 的标准配置，包括设置、快捷键、代码片段和扩展列表。

## 特性

- 集中管理 VSCode 配置
- 团队成员可以轻松下载和应用标准配置
- 仅管理员可以更新配置
- 支持 Windows、macOS 和 Linux 系统
- 自动安装所需扩展

## 目录结构

```
.
├── settings.json       # VSCode 用户设置
├── keybindings.json    # VSCode 快捷键配置
├── snippets/           # 代码片段配置
├── extensions.list     # 扩展列表
├── setup.ps1           # Windows 安装脚本
├── setup.sh           # macOS/Linux 安装脚本
├── update-config.ps1   # Windows 配置更新脚本 (仅管理员使用)
├── update-config.sh    # macOS/Linux 配置更新脚本 (仅管理员使用)
└── README.md           # 说明文档
```

## 使用方法

### 团队成员 - 安装配置

1. 克隆仓库：

   ```bash
   git clone <仓库URL> vscode-config
   ```

2. 运行安装脚本：
   - Windows: 在 PowerShell 中运行
     ```powershell
     .\setup.ps1
     ```
   - macOS/Linux: 在终端中运行
     ```bash
     ./setup.sh
     ```

### 管理员 - 更新配置

1. 修改本地 VSCode 配置
2. 运行更新脚本将修改同步到仓库：
   - Windows: 在 PowerShell 中运行
     ```powershell
     .\update-config.ps1
     ```
   - macOS/Linux: 在终端中运行
     ```bash
     ./update-config.sh
     ```
3. 提交并推送更改到远程仓库：
   ```bash
   git add .
   git commit -m "更新配置"
   git push
   ```

## 权限管理

- 将仓库设置为私有仓库
- 团队成员设置为只读权限（Reporter/Reader 角色）
- 仅管理员拥有写入权限（Maintainer/Writer 角色）

## 注意事项

- 安装脚本会覆盖现有的 VSCode 配置，请在安装前备份重要的个人配置
- 如果团队成员需要个性化设置，建议创建单独的配置文件
- 某些扩展可能需要额外的配置或登录，请参考相应扩展的文档
- 建议定期运行安装脚本以获取最新的团队配置更新
