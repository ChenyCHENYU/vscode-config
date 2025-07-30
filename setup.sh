#!/bin/bash

# VSCode 配置安装脚本 - 纯Bash版本
# 此脚本用于安装团队标准的VSCode配置
# 支持 macOS, Linux, Windows (Git Bash)
# 避免PowerShell依赖，防止卡死问题

set -e  # 遇到错误立即退出

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 参数解析
FORCE=false
SILENT=false
TIMEOUT=30

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --silent)
            SILENT=true
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --help)
            echo "VSCode配置安装脚本 - 纯Bash版本"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --force     强制安装，无交互确认"
            echo "  --silent    静默模式，不等待用户输入"
            echo "  --timeout   扩展安装超时时间(秒，默认30)"
            echo "  --help      显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 --force --silent"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 安全的用户输入函数
safe_user_input() {
    local prompt="$1"
    local default_value="$2"
    local timeout_seconds="${3:-10}"
    
    if [ "$SILENT" = true ] || [ "$FORCE" = true ]; then
        echo "$default_value"
        return
    fi
    
    echo -n "$prompt "
    
    # 使用read的超时功能
    if read -t "$timeout_seconds" -r response; then
        echo "$response"
    else
        echo ""
        echo "$default_value"
    fi
}

# 安全的扩展安装函数
install_extension() {
    local extension_id="$1"
    local timeout_seconds="$2"
    
    print_info "安装扩展: $extension_id"
    
    # 使用timeout命令来控制超时
    if command -v timeout >/dev/null 2>&1; then
        if timeout "$timeout_seconds" code --install-extension "$extension_id" --force >/dev/null 2>&1; then
            print_success "✓ 成功安装: $extension_id"
            return 0
        else
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                print_warning "⏰ 安装超时: $extension_id (${timeout_seconds}秒)"
            else
                print_error "✗ 安装失败: $extension_id (退出码: $exit_code)"
            fi
            return 1
        fi
    else
        # 如果没有timeout命令，直接尝试安装
        if code --install-extension "$extension_id" --force >/dev/null 2>&1; then
            print_success "✓ 成功安装: $extension_id"
            return 0
        else
            print_error "✗ 安装失败: $extension_id"
            return 1
        fi
    fi
}

# 主程序开始
print_info "VSCode配置安装脚本启动..."

# 检测操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
    OS_TYPE="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
    OS_TYPE="Linux"
elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
    # Windows (Git Bash/Msys/Cygwin)
    VSCODE_CONFIG_DIR="$APPDATA/Code/User"
    if [ -z "$APPDATA" ]; then
        VSCODE_CONFIG_DIR="$HOME/AppData/Roaming/Code/User"
    fi
    OS_TYPE="Windows"
else
    print_error "不支持的操作系统: $OSTYPE"
    exit 1
fi

print_info "操作系统: $OS_TYPE"
print_info "VSCode配置目录: $VSCODE_CONFIG_DIR"

# 检查VSCode是否安装
if ! command -v code >/dev/null 2>&1; then
    print_error "VSCode未安装或未添加到PATH中。请先安装VSCode。"
    exit 1
fi
print_success "VSCode 已找到"

# 创建配置目录（如果不存在）
if [ ! -d "$VSCODE_CONFIG_DIR" ]; then
    mkdir -p "$VSCODE_CONFIG_DIR"
    print_info "创建配置目录: $VSCODE_CONFIG_DIR"
fi

snippets_dir="$VSCODE_CONFIG_DIR/snippets"
if [ ! -d "$snippets_dir" ]; then
    mkdir -p "$snippets_dir"
    print_info "创建代码片段目录: $snippets_dir"
fi

# 备份现有配置
timestamp=$(date +%Y%m%d%H%M%S)
backup_dir="$VSCODE_CONFIG_DIR/backup_$timestamp"
print_info "备份现有配置到: $backup_dir"

mkdir -p "$backup_dir"
mkdir -p "$backup_dir/snippets"

# 备份settings.json
if [ -f "$VSCODE_CONFIG_DIR/settings.json" ]; then
    cp "$VSCODE_CONFIG_DIR/settings.json" "$backup_dir/"
    print_info "已备份 settings.json"
fi

# 备份keybindings.json
if [ -f "$VSCODE_CONFIG_DIR/keybindings.json" ]; then
    cp "$VSCODE_CONFIG_DIR/keybindings.json" "$backup_dir/"
    print_info "已备份 keybindings.json"
fi

# 备份代码片段
if [ -d "$snippets_dir" ] && [ "$(ls -A "$snippets_dir" 2>/dev/null)" ]; then
    cp -r "$snippets_dir/"* "$backup_dir/snippets/" 2>/dev/null || true
    print_info "已备份代码片段"
fi

# 复制配置文件
print_info "开始安装配置文件..."

# 检查并复制settings.json
if [ -f "settings.json" ]; then
    cp "settings.json" "$VSCODE_CONFIG_DIR/"
    print_success "已安装 settings.json"
else
    print_warning "未找到 settings.json 文件"
fi

# 检查并复制keybindings.json
if [ -f "keybindings.json" ]; then
    cp "keybindings.json" "$VSCODE_CONFIG_DIR/"
    print_success "已安装 keybindings.json"
else
    print_warning "未找到 keybindings.json 文件"
fi

# 检查并复制extensions.list
if [ -f "extensions.list" ]; then
    cp "extensions.list" "$VSCODE_CONFIG_DIR/"
    print_success "已安装 extensions.list"
else
    print_warning "未找到 extensions.list 文件"
fi

# 复制代码片段
if [ -d "snippets" ]; then
    source_snippets_count=$(find snippets -type f 2>/dev/null | wc -l)
    if [ "$source_snippets_count" -gt 0 ]; then
        cp -r snippets/* "$snippets_dir/" 2>/dev/null || true
        print_success "已安装代码片段 ($source_snippets_count 个文件)"
    else
        print_warning "代码片段目录为空"
    fi
else
    print_warning "未找到代码片段目录，跳过安装代码片段"
    mkdir -p "snippets"
fi

# 安装扩展
if [ -f "extensions.list" ]; then
    print_info "开始安装扩展..."
    
    # 读取扩展列表，过滤注释和空行
    extensions=$(grep -v '^#' extensions.list | grep -v '^$' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    if [ -n "$extensions" ]; then
        total_extensions=$(echo "$extensions" | wc -l)
        installed=0
        failed=0
        
        print_info "找到 $total_extensions 个扩展需要安装"
        
        # 询问是否安装扩展
        install_extensions="$FORCE"
        if [ "$install_extensions" != true ]; then
            response=$(safe_user_input "是否安装扩展? (Y/n):" "Y" 10)
            if [[ "$response" =~ ^([yY][eE][sS]|[yY]|^$) ]]; then
                install_extensions=true
            fi
        fi
        
        if [ "$install_extensions" = true ]; then
            # 安装扩展
            while IFS= read -r extension; do
                if [ -n "$extension" ]; then
                    installed=$((installed + 1))
                    
                    if install_extension "$extension" "$TIMEOUT"; then
                        # 安装成功
                        :
                    else
                        failed=$((failed + 1))
                    fi
                fi
            done <<< "$extensions"
            
            success_count=$((installed - failed))
            print_info "扩展安装完成: 成功 $success_count/$total_extensions，失败 $failed"
        else
            print_info "跳过扩展安装"
        fi
    else
        print_warning "extensions.list 文件为空或只包含注释"
    fi
else
    print_warning "未找到 extensions.list 文件，跳过安装扩展"
    
    # 创建示例扩展列表文件
    cat > extensions.list << 'EOF'
# VSCode 扩展列表示例
# 取消注释下面的行来安装对应的扩展

# ms-vscode.vscode-typescript-next
# ms-python.python
# ms-vscode.powershell
# esbenp.prettier-vscode
# ms-vscode.vscode-json
EOF
    print_info "已创建示例 extensions.list 文件"
fi

# 完成安装
echo ""
print_success "======================================"
print_success "VSCode配置安装完成！"
print_success "======================================"
print_info "备份位置: $backup_dir"
print_info "配置目录: $VSCODE_CONFIG_DIR"

# 提供恢复说明
echo ""
print_info "如需恢复之前的配置，请运行以下命令:"
echo "  cp -r '$backup_dir'/* '$VSCODE_CONFIG_DIR'/"

# 安全的结束等待
if [ "$SILENT" != true ] && [ "$FORCE" != true ]; then
    response=$(safe_user_input "按 Enter 键退出或等待5秒自动退出..." "" 5)
    if [ -n "$response" ]; then
        print_info "用户确认退出"
    else
        print_info "自动退出"
    fi
fi

print_info "脚本执行完成，感谢使用！"