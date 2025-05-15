#!/bin/bash

# VSCode 配置更新脚本 - macOS/Linux版本
# 此脚本用于管理员从本地VSCode配置更新到仓库

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Git是否安装
if ! command -v git &> /dev/null; then
    print_error "Git未安装。请先安装Git。"
    exit 1
fi

# 检查是否在Git仓库中
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    print_error "当前目录不是Git仓库。请在VSCode配置仓库目录中运行此脚本。"
    exit 1
fi

# 确定VSCode配置目录
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
    # Windows (Git Bash/Msys/Cygwin)
    VSCODE_CONFIG_DIR="$APPDATA/Code/User"
    if [ -z "$APPDATA" ]; then
        # 如果 APPDATA 环境变量未定义，尝试使用 Windows 默认路径
        VSCODE_CONFIG_DIR="$HOME/AppData/Roaming/Code/User"
    fi
else
    print_error "不支持的操作系统: $OSTYPE"
    exit 1
fi

print_message "VSCode配置目录: $VSCODE_CONFIG_DIR"

# 检查VSCode配置目录是否存在
if [ ! -d "$VSCODE_CONFIG_DIR" ]; then
    print_error "VSCode配置目录不存在: $VSCODE_CONFIG_DIR"
    exit 1
fi

# 更新settings.json
if [ -f "$VSCODE_CONFIG_DIR/settings.json" ]; then
    print_message "更新 settings.json"
    cp "$VSCODE_CONFIG_DIR/settings.json" .
else
    print_warning "VSCode settings.json 不存在，跳过更新"
fi

# 更新keybindings.json
if [ -f "$VSCODE_CONFIG_DIR/keybindings.json" ]; then
    print_message "更新 keybindings.json"
    cp "$VSCODE_CONFIG_DIR/keybindings.json" .
else
    print_warning "VSCode keybindings.json 不存在，跳过更新"
fi

# 更新代码片段
if [ -d "$VSCODE_CONFIG_DIR/snippets" ]; then
    print_message "更新代码片段"
    
    # 确保snippets目录存在
    mkdir -p snippets
    
    # 清空现有代码片段目录（避免保留已删除的片段）
    rm -rf snippets/*
    
    # 复制所有代码片段
    cp -r "$VSCODE_CONFIG_DIR/snippets/"* snippets/ 2>/dev/null || true
    
    # 检查是否有代码片段被复制
    if [ "$(ls -A snippets 2>/dev/null)" ]; then
        print_message "代码片段已更新"
    else
        print_warning "没有找到代码片段，snippets目录为空"
    fi
else
    print_warning "VSCode snippets 目录不存在，跳过更新代码片段"
    # 创建snippets目录以备将来使用
    mkdir -p snippets
fi

# 更新扩展列表
print_message "更新扩展列表"

# 创建带有注释头的新扩展列表
cat > extensions.list << EOL
# VSCode 扩展列表
# 此文件由update-config.sh脚本自动生成
# 更新时间: $(date)
#
# 每行一个扩展ID

$(code --list-extensions)
EOL

print_message "配置更新完成！"
print_message "请检查更改，然后使用Git提交并推送更改："
echo "  git add ."
echo "  git commit -m \"更新VSCode配置\""
echo "  git push"