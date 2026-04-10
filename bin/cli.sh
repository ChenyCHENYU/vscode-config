#!/bin/bash

# VSCode 配置管理 CLI 入口
# 通过 npx 或全局安装后使用: vscode-config <command>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "VSCode 团队配置管理工具 v$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "unknown")"
    echo ""
    echo "用法: vscode-config <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  install          下载并安装配置（覆盖模式）"
    echo "  install:extend   下载并安装配置（扩展模式，保留个人扩展）"
    echo "  install:merge    下载并安装配置（合并模式，深度合并settings.json）"
    echo "  upload           上传本地配置到远程仓库"
    echo "  sync             仅同步扩展（覆盖模式）"
    echo "  sync:extend      仅同步扩展（扩展模式）"
    echo "  dry-run          干运行：预览将要执行的操作"
    echo "  diff             预览本地与团队配置的差异"
    echo "  version          显示版本号"
    echo "  help             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  vscode-config install          # 首次安装（推荐）"
    echo "  vscode-config install:extend   # 保留个人扩展"
    echo "  vscode-config dry-run          # 先看看会做什么"
    echo "  vscode-config diff             # 预览配置差异"
}

case "${1:-help}" in
    install)
        bash "$SCRIPT_DIR/download.sh"
        ;;
    install:extend)
        bash "$SCRIPT_DIR/download-extend.sh"
        ;;
    install:merge)
        bash "$SCRIPT_DIR/download-config.sh" --auto-pull --force --mode extend
        bash "$SCRIPT_DIR/setup.sh" --force --silent --merge --mode extend
        ;;
    upload)
        bash "$SCRIPT_DIR/upload.sh"
        ;;
    sync)
        bash "$SCRIPT_DIR/sync.sh"
        ;;
    sync:extend)
        bash "$SCRIPT_DIR/sync-extend.sh"
        ;;
    dry-run)
        bash "$SCRIPT_DIR/setup.sh" --force --silent --dry-run --mode "${2:-overwrite}"
        ;;
    diff)
        bash "$SCRIPT_DIR/setup.sh" --force --silent --diff --dry-run --mode "${2:-overwrite}"
        ;;
    version|-v|--version)
        cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "unknown"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
