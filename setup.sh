#!/bin/bash

# VSCode 配置安装脚本 - 纯Bash版本
# 此脚本用于安装团队标准的VSCode配置
# 支持 macOS, Linux, Windows (Git Bash)
# 避免PowerShell依赖，防止卡死问题
# 版本: 1.2.0

set -e  # 遇到错误立即退出

# 切换到脚本所在目录，确保相对路径正确
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印带颜色的消息（提前定义，供参数验证使用）
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

# 参数解析
FORCE=false
SILENT=false
TIMEOUT=30
SYNC_MODE="overwrite"  # overwrite 或 extend
DRY_RUN=false
DIFF_PREVIEW=false
MERGE_SETTINGS=false

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
        --mode)
            SYNC_MODE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --diff)
            DIFF_PREVIEW=true
            shift
            ;;
        --merge)
            MERGE_SETTINGS=true
            shift
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
            echo "  --mode MODE 扩展同步模式: overwrite(覆盖) 或 extend(扩展)"
            echo "  --dry-run   干运行模式，只预览变更不实际执行"
            echo "  --diff      安装前显示配置文件差异预览"
            echo "  --merge     合并模式，将团队配置与本地配置深度合并(需要node)"
            echo "  --help      显示此帮助信息"
            echo ""
            echo "同步模式说明:"
            echo "  overwrite - 覆盖模式：安装列表中的扩展，卸载不在列表中的扩展"
            echo "  extend    - 扩展模式：只安装列表中缺失的扩展，不卸载任何扩展"
            echo ""
            echo "示例:"
            echo "  $0 --force --silent --mode overwrite"
            echo "  $0 --force --mode extend"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 验证同步模式
if [[ "$SYNC_MODE" != "overwrite" && "$SYNC_MODE" != "extend" ]]; then
    print_error "无效的同步模式: $SYNC_MODE。请使用 'overwrite' 或 'extend'"
    exit 1
fi

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

# 配置差异预览函数
show_config_diff() {
    local source_file="$1"
    local target_file="$2"
    local label="$3"
    
    if [ ! -f "$source_file" ]; then
        return
    fi
    
    if [ ! -f "$target_file" ]; then
        print_info "$label: 目标不存在，将直接复制（新增 $(wc -l < "$source_file") 行）"
        return
    fi
    
    if diff -q "$source_file" "$target_file" >/dev/null 2>&1; then
        print_info "$label: 无差异"
    else
        echo -e "${BOLD}${BLUE}📋 $label 差异预览:${NC}"
        echo -e "${GRAY}────────────────────────────────────────${NC}"
        # 使用 diff 显示差异，限制输出行数防止刷屏
        diff --color=auto -u "$target_file" "$source_file" 2>/dev/null | head -40 || \
        diff -u "$target_file" "$source_file" 2>/dev/null | head -40 || true
        local total_diff=$(diff -u "$target_file" "$source_file" 2>/dev/null | wc -l)
        if [ "$total_diff" -gt 40 ]; then
            echo -e "${GRAY}  ... 还有 $((total_diff - 40)) 行差异未显示${NC}"
        fi
        echo -e "${GRAY}────────────────────────────────────────${NC}"
    fi
}

# JSON 深度合并函数（需要 node）
merge_json_settings() {
    local team_file="$1"
    local local_file="$2"
    local output_file="$3"
    
    if [ ! -f "$local_file" ]; then
        cp "$team_file" "$output_file"
        return 0
    fi
    
    if ! command -v node >/dev/null 2>&1; then
        print_warning "未找到 node，无法使用合并模式，将回退为覆盖模式"
        cp "$team_file" "$output_file"
        return 0
    fi
    
    # 使用 node 进行 JSON 深度合并：团队配置优先，保留本地独有项
    node -e "
const fs = require('fs');
function stripComments(s) {
    return s.replace(/\/\/.*$/gm, '').replace(/\/\*[\s\S]*?\*\//g, '');
}
try {
    const local = JSON.parse(stripComments(fs.readFileSync('$local_file', 'utf8')));
    const team = JSON.parse(stripComments(fs.readFileSync('$team_file', 'utf8')));
    // 深度合并：本地为基底，团队配置覆盖
    const merged = { ...local, ...team };
    // 对于对象类型的值，也进行浅合并
    for (const key of Object.keys(team)) {
        if (team[key] && typeof team[key] === 'object' && !Array.isArray(team[key])
            && local[key] && typeof local[key] === 'object' && !Array.isArray(local[key])) {
            merged[key] = { ...local[key], ...team[key] };
        }
    }
    fs.writeFileSync('$output_file', JSON.stringify(merged, null, 2) + '\n');
    process.exit(0);
} catch(e) {
    process.stderr.write('JSON合并失败: ' + e.message + '\n');
    process.exit(1);
}
" 2>&1
    return $?
}

# 锁文件机制
LOCK_FILE="$SCRIPT_DIR/.vscode-config.lock"

check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            print_error "另一个安装脚本正在运行 (PID: $lock_pid)，请等待其完成"
            exit 1
        else
            print_warning "发现过期的锁文件，已自动清理"
            rm -f "$LOCK_FILE"
        fi
    fi
}

release_lock() {
    rm -f "$LOCK_FILE"
}

trap release_lock EXIT INT TERM

# 主程序开始
print_info "VSCode配置安装脚本启动..."

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} 干运行模式：只预览变更，不实际执行"
    echo ""
fi

if [ "$DRY_RUN" != true ]; then
    check_lock
    echo $$ > "$LOCK_FILE"
else
    check_lock
fi

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

# 差异预览
if [ "$DIFF_PREVIEW" = true ] || [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${BOLD}${BLUE}🔍 配置差异预览:${NC}"
    show_config_diff "settings.json" "$VSCODE_CONFIG_DIR/settings.json" "settings.json"
    echo ""
    show_config_diff "keybindings.json" "$VSCODE_CONFIG_DIR/keybindings.json" "keybindings.json"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[干运行] 将复制配置文件到: $VSCODE_CONFIG_DIR"
        if [ -d "snippets" ]; then
            local_snippets=$(find snippets -type f 2>/dev/null | wc -l)
            print_info "[干运行] 将安装 $local_snippets 个代码片段"
        fi
    fi
fi

if [ "$DRY_RUN" != true ]; then

# 检查并复制settings.json
if [ -f "settings.json" ]; then
    if [ "$MERGE_SETTINGS" = true ]; then
        print_info "合并模式: 深度合并 settings.json..."
        if merge_json_settings "settings.json" "$VSCODE_CONFIG_DIR/settings.json" "$VSCODE_CONFIG_DIR/settings.json"; then
            print_success "已合并安装 settings.json（团队配置优先，保留本地独有项）"
        else
            print_warning "合并失败，回退为覆盖模式"
            cp "settings.json" "$VSCODE_CONFIG_DIR/"
            print_success "已覆盖安装 settings.json"
        fi
    else
        cp "settings.json" "$VSCODE_CONFIG_DIR/"
        print_success "已安装 settings.json"
    fi
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

fi  # end of DRY_RUN != true block

# 安装扩展
if [ -f "extensions.list" ]; then
    print_info "开始同步扩展..."
    
    # 询问是否同步扩展
    sync_extensions="$FORCE"
    if [ "$sync_extensions" != true ]; then
        response=$(safe_user_input "是否同步扩展? (Y/n):" "Y" 10)
        if [[ "$response" =~ ^([yY][eE][sS]|[yY]|^$) ]]; then
            sync_extensions=true
        fi
    fi
    
    if [ "$sync_extensions" = true ]; then
        # 调用扩展同步脚本
        sync_args=""
        if [ "$FORCE" = true ]; then
            sync_args="$sync_args --force"
        fi
        if [ "$SILENT" = true ]; then
            sync_args="$sync_args --silent"
        fi
        if [ "$DRY_RUN" = true ]; then
            sync_args="$sync_args --dry-run"
        fi
        sync_args="$sync_args --timeout $TIMEOUT"
        sync_args="$sync_args --mode $SYNC_MODE"
        
        # 运行同步脚本
        if bash sync-extensions.sh $sync_args; then
            print_success "✓ 扩展同步完成"
        else
            print_error "扩展同步失败"
            exit 1
        fi
    else
        print_info "跳过扩展同步"
    fi
else
    print_warning "未找到 extensions.list 文件，跳过同步扩展"
    
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