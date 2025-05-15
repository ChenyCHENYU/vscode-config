#!/bin/bash

# VSCode 配置安装脚本 - macOS/Linux版本
# 此脚本用于安装团队标准的VSCode配置

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

# 检查VSCode是否安装
if ! command -v code &> /dev/null; then
    print_error "VSCode未安装或未添加到PATH中。请先安装VSCode。"
    exit 1
fi

# 确定VSCode配置目录
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
else
    print_error "不支持的操作系统: $OSTYPE"
    exit 1
fi

print_message "VSCode配置目录: $VSCODE_CONFIG_DIR"

# 创建配置目录（如果不存在）
mkdir -p "$VSCODE_CONFIG_DIR"
mkdir -p "$VSCODE_CONFIG_DIR/snippets"

# 备份现有配置
BACKUP_DIR="$VSCODE_CONFIG_DIR/backup_$(date +%Y%m%d%H%M%S)"
print_message "备份现有配置到: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/snippets"

# 备份settings.json
if [ -f "$VSCODE_CONFIG_DIR/settings.json" ]; then
    cp "$VSCODE_CONFIG_DIR/settings.json" "$BACKUP_DIR/"
fi

# 备份keybindings.json
if [ -f "$VSCODE_CONFIG_DIR/keybindings.json" ]; then
    cp "$VSCODE_CONFIG_DIR/keybindings.json" "$BACKUP_DIR/"
fi

# 备份代码片段
if [ -d "$VSCODE_CONFIG_DIR/snippets" ]; then

# 复制keybindings.json
cp "keybindings.json" "$VSCODE_CONFIG_DIR/"
print_message "已安装 keybindings.json"

# 复制代码片段
if [ -d "snippets" ]; then
    cp -r snippets/* "$VSCODE_CONFIG_DIR/snippets/"
    print_message "已安装代码片段"
else
    print_warning "未找到代码片段目录，跳过安装代码片段"
    # 创建snippets目录以备将来使用
    mkdir -p "snippets"
fi

# 安装扩展
if [ -f "extensions.list" ]; then
    print_message "开始安装扩展..."
    
    # 统计扩展总数
    TOTAL_EXTENSIONS=$(grep -v '^#' extensions.list | grep -v '^$' | wc -l)
    TOTAL_EXTENSIONS=$(echo $TOTAL_EXTENSIONS | tr -d ' ')
    INSTALLED=0
    
    # 读取并安装扩展
    while IFS= read -r extension || [ -n "$extension" ]; do
        # 跳过注释和空行
        if [[ $extension == \#* ]] || [[ -z $extension ]]; then
            continue
        fi
        
        print_message "安装扩展 ($((++INSTALLED))/$TOTAL_EXTENSIONS): $extension"
        code --install-extension "$extension" --force
    done < "extensions.list"
    
    print_message "扩展安装完成: $INSTALLED/$TOTAL_EXTENSIONS"
else
    print_warning "未找到extensions.list文件，跳过安装扩展"
fi

print_message "VSCode配置安装完成！"
print_message "如果您需要恢复之前的配置，备份文件位于: $BACKUP_DIR"