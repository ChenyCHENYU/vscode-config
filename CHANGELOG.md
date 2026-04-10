# Changelog

本文件记录 vscode-config 项目的所有显著变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.2.0] - 2026-04-10

### 新增
- **分批安装** — 扩展安装改为每10个一批，避免单次调用参数过长或网络超时
- **锁文件机制** — 防止多终端同时运行安装/同步脚本导致冲突，自动检测过期锁
- **干运行模式 (`--dry-run`)** — 只预览将要安装/卸载的扩展，不实际执行
- **配置差异预览 (`--diff`)** — 安装前显示本地与团队 settings.json/keybindings.json 差异
- **settings.json 合并模式 (`--merge`)** — 深度合并团队配置与本地配置（团队优先，保留本地独有项，需 node）
- **npm 包封装** — 支持 `npx vscode-config install` 等命令，降低使用门槛
- **CLI 入口 (`bin/cli.sh`)** — 统一命令入口，支持 install/upload/sync/dry-run/diff/version 等子命令

### 优化
- 扩展安装从单次全量调用改为分批（每批10个），提升大列表场景稳定性

## [1.1.0] - 2026-04-10

### 修复

- **🔴 致命修复: 扩展安装不再重复打开窗口** — 将逐个 `code --install-extension` 调用改为单次批量调用，从根本上解决安装39个扩展时弹出39个VS Code窗口的问题
- **🔴 致命修复: `print_error` 函数定义顺序** — `setup.sh` 中 `print_error` 在参数验证阶段被调用但尚未定义，导致验证失败时报语法错误而非友好提示
- **🟡 修复: 扩展名大小写不敏感比较** — 之前使用 `grep -q "^${ext}$"` 区分大小写，VS Code扩展ID不区分大小写，导致误安装/误卸载
- **🟡 修复: 脚本相对路径问题** — 所有快捷脚本从其他目录调用时会找不到文件，现在使用 `SCRIPT_DIR` 确保路径正确
- **🟡 修复: 缺少 `.gitignore`** — 备份目录 `.backup_local_changes_*` 可能被意外提交到 Git
- **🟠 修复: 扩展列表空行处理** — `echo -e "$to_install"` 产生的空行会导致对空字符串调用安装命令
- **🟠 修复: `wc -l` 计数偏差** — 空字符串时 `wc -l` 返回错误计数，改用 `grep -c .`

### 新增

- 添加 `VERSION` 文件进行版本管理
- 添加 `CHANGELOG.md` 变更日志
- 添加 `.gitignore` 文件
- 批量安装后自动验证 + 失败重试机制
- 所有脚本使用 `SCRIPT_DIR` 自动定位目录

### 优化

- 扩展安装从逐个串行改为批量单次调用，显著提升安装速度
- 使用数组替代字符串拼接处理扩展列表，消除空行和计数问题
- 移除 `setup.sh` 中未使用的 `install_extension` 函数（扩展安装已委托给 `sync-extensions.sh`）

## [1.0.0] - 2025-10-03

### 初始版本

- VSCode 配置集中管理（settings.json, keybindings.json, snippets）
- 扩展列表同步（覆盖模式 / 扩展模式）
- 自动备份现有配置
- 上传/下载/同步快捷脚本
- 多远程仓库推送支持
- 美化的 Git 状态显示
- 跨平台支持（macOS, Linux, Windows Git Bash）
