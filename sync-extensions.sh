#!/bin/bash

# VSCode 扩展同步脚本 - 处理扩展的安装和卸载
# 此脚本用于同步VSCode扩展，包括安装新扩展和卸载已删除的扩展

set -e  # 遇到错误立即退出

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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

# 参数解析
FORCE=false
SILENT=false
TIMEOUT=30
SYNC_MODE="overwrite"  # overwrite 或 extend

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
        --help)
            echo -e "${BOLD}VSCode扩展同步脚本${NC}"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --force         强制执行，无交互确认"
            echo "  --silent        静默模式，不等待用户输入"
            echo "  --timeout N     扩展安装超时时间(秒，默认30)"
            echo "  --mode MODE     同步模式: overwrite(覆盖) 或 extend(扩展)"
            echo "  --help          显示此帮助信息"
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
            print_error "未知参数: $1"
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

# 安全的扩展卸载函数
uninstall_extension() {
    local extension_id="$1"
    
    print_info "卸载扩展: $extension_id"
    
    if code --uninstall-extension "$extension_id" >/dev/null 2>&1; then
        print_success "✓ 成功卸载: $extension_id"
        return 0
    else
        print_error "✗ 卸载失败: $extension_id"
        return 1
    fi
}

# 主程序开始
echo -e "${BOLD}${CYAN}🔄 VSCode扩展同步脚本${NC}"
echo -e "${GRAY}════════════════════════════════════════${NC}"

# 检查VSCode是否安装
if ! command -v code >/dev/null 2>&1; then
    print_error "VSCode未安装或未添加到PATH中。请先安装VSCode。"
    exit 1
fi
print_success "VSCode 已找到"

# 检查extensions.list文件是否存在
if [ ! -f "extensions.list" ]; then
    print_error "未找到 extensions.list 文件"
    exit 1
fi

# 获取当前已安装的扩展
print_info "获取当前已安装的扩展..."
current_extensions=$(code --list-extensions 2>/dev/null || echo "")

# 获取目标扩展列表
print_info "读取目标扩展列表..."
target_extensions=$(grep -v '^#' extensions.list | grep -v '^$' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

# 显示扩展信息
echo ""
echo -e "${BOLD}${BLUE}📊 扩展统计信息:${NC}"
current_count=$(echo "$current_extensions" | wc -l)
target_count=$(echo "$target_extensions" | wc -l)
echo -e "   ${GRAY}当前已安装: ${BOLD}$current_count${NC} 个扩展"
echo -e "   ${GRAY}目标列表: ${BOLD}$target_count${NC} 个扩展"

# 找出需要安装的扩展（在目标列表中但未安装）
echo ""
echo -e "${BOLD}${YELLOW}📥 检查需要安装的扩展...${NC}"
to_install=""
while IFS= read -r target_ext; do
    if [ -n "$target_ext" ] && ! echo "$current_extensions" | grep -q "^${target_ext}$"; then
        to_install="${to_install}${target_ext}\n"
    fi
done <<< "$target_extensions"

if [ -n "$to_install" ]; then
    install_count=$(echo -e "$to_install" | wc -l)
    print_info "发现 ${BOLD}$install_count${NC} 个需要安装的扩展"
    echo -e "${to_install}" | sed 's/^/   - /'
    
    # 询问是否安装扩展
    should_install="$FORCE"
    if [ "$should_install" != true ]; then
        response=$(safe_user_input "是否安装这些扩展? (Y/n):" "Y" 10)
        if [[ "$response" =~ ^([yY][eE][sS]|[yY]|^$) ]]; then
            should_install=true
        fi
    fi
    
    if [ "$should_install" = true ]; then
        installed=0
        failed=0
        
        # 安装扩展
        while IFS= read -r extension; do
            if [ -n "$extension" ]; then
                if install_extension "$extension" "$TIMEOUT"; then
                    installed=$((installed + 1))
                else
                    failed=$((failed + 1))
                fi
            fi
        done <<< "$(echo -e "$to_install")"
        
        print_info "扩展安装完成: 成功 $installed/$install_count，失败 $failed"
    else
        print_info "跳过扩展安装"
    fi
else
    print_success "✓ 所有目标扩展已安装"
fi

# 找出需要卸载的扩展（已安装但不在目标列表中）
if [ "$SYNC_MODE" = "overwrite" ]; then
    echo ""
    echo -e "${BOLD}${RED}📤 检查需要卸载的扩展...${NC}"
    to_uninstall=""
    while IFS= read -r current_ext; do
        if [ -n "$current_ext" ] && ! echo "$target_extensions" | grep -q "^${current_ext}$"; then
            to_uninstall="${to_uninstall}${current_ext}\n"
        fi
    done <<< "$current_extensions"
    
    if [ -n "$to_uninstall" ]; then
        uninstall_count=$(echo -e "$to_uninstall" | wc -l)
        print_info "发现 ${BOLD}$uninstall_count${NC} 个需要卸载的扩展"
        echo -e "${to_uninstall}" | sed 's/^/   - /'
        
        # 询问是否卸载扩展
        should_uninstall="$FORCE"
        if [ "$should_uninstall" != true ]; then
            response=$(safe_user_input "是否卸载这些扩展? (y/N):" "N" 10)
            if [[ "$response" =~ ^([yY][eE][sS]|[yY]) ]]; then
                should_uninstall=true
            fi
        fi
        
        if [ "$should_uninstall" = true ]; then
            uninstalled=0
            failed=0
            
            # 卸载扩展
            while IFS= read -r extension; do
                if [ -n "$extension" ]; then
                    if uninstall_extension "$extension"; then
                        uninstalled=$((uninstalled + 1))
                    else
                        failed=$((failed + 1))
                    fi
                fi
            done <<< "$(echo -e "$to_uninstall")"
            
            print_info "扩展卸载完成: 成功 $uninstalled/$uninstall_count，失败 $failed"
        else
            print_info "跳过扩展卸载"
        fi
    else
        print_success "✓ 没有需要卸载的扩展"
    fi
else
    print_info "扩展模式：不卸载任何扩展，只安装缺失的扩展"
fi

# 完成信息
echo ""
echo -e "${BOLD}${GREEN}🎉 VSCode扩展同步完成！${NC}"
echo -e "${GRAY}════════════════════════════════════════${NC}"

# 显示最终状态
final_extensions=$(code --list-extensions 2>/dev/null || echo "")
final_count=$(echo "$final_extensions" | wc -l)
echo -e "${BOLD}📊 最终状态:${NC}"
echo -e "   ${GRAY}当前已安装: ${BOLD}$final_count${NC} 个扩展"

echo ""
echo -e "${GRAY}感谢使用VSCode扩展同步脚本！${NC}"