#!/bin/bash

# VSCode 扩展同步脚本 - 处理扩展的安装和卸载
# 此脚本用于同步VSCode扩展，包括安装新扩展和卸载已删除的扩展
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
DRY_RUN=false

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
            echo "  --dry-run       干运行模式，只显示将要执行的操作，不实际执行"
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

# 安全的扩展安装函数（分批模式，每批10个）
BATCH_SIZE=10

batch_install_extensions() {
    local extensions=("$@")
    local total=${#extensions[@]}
    local installed=0
    local failed=0
    local failed_list=()
    
    if [ $total -eq 0 ]; then
        return 0
    fi
    
    # 分批安装，每批 BATCH_SIZE 个
    local batch_num=$(( (total + BATCH_SIZE - 1) / BATCH_SIZE ))
    print_info "分 $batch_num 批安装 $total 个扩展（每批最多 $BATCH_SIZE 个）..."
    
    for (( batch=0; batch<batch_num; batch++ )); do
        local start=$(( batch * BATCH_SIZE ))
        local end=$(( start + BATCH_SIZE ))
        if [ $end -gt $total ]; then end=$total; fi
        
        local batch_exts=("${extensions[@]:$start:$BATCH_SIZE}")
        local batch_count=${#batch_exts[@]}
        
        echo ""
        print_info "第 $((batch+1))/$batch_num 批（$batch_count 个扩展）..."
        
        # 构建批量安装参数
        local install_args=()
        for ext in "${batch_exts[@]}"; do
            install_args+=(--install-extension "$ext")
        done
        
        if command -v timeout >/dev/null 2>&1; then
            local batch_timeout=$(( TIMEOUT * batch_count + 60 ))
            timeout "$batch_timeout" code "${install_args[@]}" --force 2>&1 | while IFS= read -r line; do
                echo "  $line"
            done || true
        else
            code "${install_args[@]}" --force 2>&1 | while IFS= read -r line; do
                echo "  $line"
            done || true
        fi
    done
    
    # 验证安装结果
    echo ""
    print_info "验证安装结果..."
    local current_after=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
    
    for ext in "${extensions[@]}"; do
        local ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        if echo "$current_after" | grep -qi "^${ext_lower}$"; then
            installed=$((installed + 1))
            print_success "✓ 已安装: $ext"
        else
            failed=$((failed + 1))
            failed_list+=("$ext")
            print_error "✗ 安装失败: $ext"
        fi
    done
    
    # 对失败的扩展逐个重试一次
    if [ ${#failed_list[@]} -gt 0 ]; then
        echo ""
        print_info "重试 ${#failed_list[@]} 个失败的扩展..."
        for ext in "${failed_list[@]}"; do
            if install_extension_single "$ext" "$TIMEOUT"; then
                installed=$((installed + 1))
                failed=$((failed - 1))
            fi
        done
    fi
    
    print_info "扩展安装完成: 成功 $installed/$total，失败 $failed"
    return 0
}

# 单个扩展安装函数（用于重试）
install_extension_single() {
    local extension_id="$1"
    local timeout_seconds="$2"
    
    print_info "重试安装: $extension_id"
    
    if command -v timeout >/dev/null 2>&1; then
        if timeout "$timeout_seconds" code --install-extension "$extension_id" --force >/dev/null 2>&1; then
            print_success "✓ 重试成功: $extension_id"
            return 0
        else
            print_error "✗ 重试失败: $extension_id"
            return 1
        fi
    else
        if code --install-extension "$extension_id" --force >/dev/null 2>&1; then
            print_success "✓ 重试成功: $extension_id"
            return 0
        else
            print_error "✗ 重试失败: $extension_id"
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

if [ "$DRY_RUN" = true ]; then
    echo -e "${BOLD}${YELLOW}🔍 干运行模式：只显示操作计划，不实际执行${NC}"
    echo ""
fi

# 锁文件机制：防止并发运行
LOCK_FILE="$SCRIPT_DIR/.vscode-config.lock"

check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        # 检查持锁进程是否还活着
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            print_error "另一个同步脚本正在运行 (PID: $lock_pid)，请等待其完成或删除锁文件: $LOCK_FILE"
            exit 1
        else
            print_warning "发现过期的锁文件（进程已结束），已自动清理"
            rm -f "$LOCK_FILE"
        fi
    fi
}

acquire_lock() {
    check_lock
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# 确保脚本退出时释放锁
trap release_lock EXIT INT TERM

# 总是检查锁，但干运行模式不创建新锁
check_lock
if [ "$DRY_RUN" != true ]; then
    echo $$ > "$LOCK_FILE"
fi

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

# 获取当前已安装的扩展（转为小写用于比较）
print_info "获取当前已安装的扩展..."
current_extensions=$(code --list-extensions 2>/dev/null || echo "")
current_extensions_lower=$(echo "$current_extensions" | tr '[:upper:]' '[:lower:]')

# 获取目标扩展列表（过滤注释和空行，去除首尾空格）
print_info "读取目标扩展列表..."
target_extensions=$(grep -v '^#' extensions.list | grep -v '^[[:space:]]*$' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

# 显示扩展信息
echo ""
echo -e "${BOLD}${BLUE}📊 扩展统计信息:${NC}"
current_count=$(echo "$current_extensions" | grep -c . || echo "0")
target_count=$(echo "$target_extensions" | grep -c . || echo "0")
echo -e "   ${GRAY}当前已安装: ${BOLD}$current_count${NC} 个扩展"
echo -e "   ${GRAY}目标列表: ${BOLD}$target_count${NC} 个扩展"

# 找出需要安装的扩展（在目标列表中但未安装，忽略大小写）
echo ""
echo -e "${BOLD}${YELLOW}📥 检查需要安装的扩展...${NC}"
to_install=()
while IFS= read -r target_ext; do
    if [ -z "$target_ext" ]; then continue; fi
    local_lower=$(echo "$target_ext" | tr '[:upper:]' '[:lower:]')
    if ! echo "$current_extensions_lower" | grep -qi "^${local_lower}$"; then
        to_install+=("$target_ext")
    fi
done <<< "$target_extensions"

if [ ${#to_install[@]} -gt 0 ]; then
    install_count=${#to_install[@]}
    print_info "发现 ${BOLD}$install_count${NC} 个需要安装的扩展"
    for ext in "${to_install[@]}"; do
        echo "   - $ext"
    done
    
    # 询问是否安装扩展
    should_install="$FORCE"
    if [ "$should_install" != true ]; then
        response=$(safe_user_input "是否安装这些扩展? (Y/n):" "Y" 10)
        if [[ "$response" =~ ^([yY][eE][sS]|[yY]|^$) ]]; then
            should_install=true
        fi
    fi
    
    if [ "$should_install" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            print_info "[干运行] 将安装以上 $install_count 个扩展（实际不执行）"
        else
            batch_install_extensions "${to_install[@]}"
        fi
    else
        print_info "跳过扩展安装"
    fi
else
    print_success "✓ 所有目标扩展已安装"
fi

# 找出需要卸载的扩展（已安装但不在目标列表中，忽略大小写）
if [ "$SYNC_MODE" = "overwrite" ]; then
    echo ""
    echo -e "${BOLD}${RED}📤 检查需要卸载的扩展...${NC}"
    target_extensions_lower=$(echo "$target_extensions" | tr '[:upper:]' '[:lower:]')
    to_uninstall=()
    while IFS= read -r current_ext; do
        if [ -z "$current_ext" ]; then continue; fi
        local_lower=$(echo "$current_ext" | tr '[:upper:]' '[:lower:]')
        if ! echo "$target_extensions_lower" | grep -qi "^${local_lower}$"; then
            to_uninstall+=("$current_ext")
        fi
    done <<< "$current_extensions"
    
    if [ ${#to_uninstall[@]} -gt 0 ]; then
        uninstall_count=${#to_uninstall[@]}
        print_info "发现 ${BOLD}$uninstall_count${NC} 个需要卸载的扩展"
        for ext in "${to_uninstall[@]}"; do
            echo "   - $ext"
        done
        
        # 询问是否卸载扩展
        should_uninstall="$FORCE"
        if [ "$should_uninstall" != true ]; then
            response=$(safe_user_input "是否卸载这些扩展? (y/N):" "N" 10)
            if [[ "$response" =~ ^([yY][eE][sS]|[yY]) ]]; then
                should_uninstall=true
            fi
        fi
        
        if [ "$should_uninstall" = true ]; then
            if [ "$DRY_RUN" = true ]; then
                print_info "[干运行] 将卸载以上 $uninstall_count 个扩展（实际不执行）"
            else
                uninstalled=0
                failed=0
                
                for extension in "${to_uninstall[@]}"; do
                    if uninstall_extension "$extension"; then
                        uninstalled=$((uninstalled + 1))
                    else
                        failed=$((failed + 1))
                    fi
                done
                
                print_info "扩展卸载完成: 成功 $uninstalled/$uninstall_count，失败 $failed"
            fi
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
if [ "$DRY_RUN" = true ]; then
    echo -e "${BOLD}${YELLOW}🔍 干运行完成，以上为操作计划，未实际执行任何操作${NC}"
else
    echo -e "${BOLD}${GREEN}🎉 VSCode扩展同步完成！${NC}"
fi
echo -e "${GRAY}════════════════════════════════════════${NC}"

# 显示最终状态
if [ "$DRY_RUN" != true ]; then
    final_extensions=$(code --list-extensions 2>/dev/null || echo "")
    final_count=$(echo "$final_extensions" | grep -c . || echo "0")
    echo -e "${BOLD}📊 最终状态:${NC}"
    echo -e "   ${GRAY}当前已安装: ${BOLD}$final_count${NC} 个扩展"
fi

echo ""
echo -e "${GRAY}感谢使用VSCode扩展同步脚本！${NC}"