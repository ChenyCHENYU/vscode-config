#!/bin/bash

# VSCode 配置下载脚本 - 从远程仓库获取最新配置
# 此脚本用于从远程仓库下载最新的VSCode配置

set -e  # 遇到错误立即退出

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
AUTO_PULL=false
FORCE=false
BACKUP=true
CLEAN=false
SYNC_MODE="overwrite"  # overwrite 或 extend

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-pull)
            AUTO_PULL=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --no-backup)
            BACKUP=false
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --mode)
            SYNC_MODE="$2"
            shift 2
            ;;
        --help)
            echo -e "${BOLD}VSCode配置下载脚本${NC}"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --auto-pull     自动拉取最新更改"
            echo "  --force         强制执行，无交互"
            echo "  --no-backup     跳过备份步骤"
            echo "  --clean         清理本地未跟踪的文件"
            echo "  --mode MODE     扩展同步模式: overwrite(覆盖) 或 extend(扩展)"
            echo "  --help          显示此帮助信息"
            echo ""
            echo "同步模式说明:"
            echo "  overwrite - 覆盖模式：安装列表中的扩展，卸载不在列表中的扩展"
            echo "  extend    - 扩展模式：只安装列表中缺失的扩展，不卸载任何扩展"
            echo ""
            echo "示例:"
            echo "  $0 --auto-pull --force --mode overwrite"
            echo "  $0 --auto-pull --force --mode extend"
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

# 主程序开始
echo -e "${BOLD}${CYAN}📥 VSCode配置下载脚本${NC}"
echo -e "${GRAY}════════════════════════════════════════${NC}"

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

# 检查远程仓库
if ! git remote get-url origin &> /dev/null; then
    print_error "未找到远程仓库配置。请确保已配置远程仓库。"
    exit 1
fi

# 获取当前分支
current_branch=$(git branch --show-current 2>/dev/null || echo "main")
print_info "当前分支: ${BOLD}$current_branch${NC}"

# 显示远程仓库信息
remote_url=$(git remote get-url origin 2>/dev/null)
print_info "远程仓库: ${GRAY}$remote_url${NC}"

# 备份当前本地修改
if [ "$BACKUP" = true ]; then
    echo ""
    echo -e "${BOLD}${YELLOW}💾 备份当前本地修改...${NC}"
    
    # 创建临时备份目录
    timestamp=$(date +%Y%m%d%H%M%S)
    backup_dir=".backup_local_changes_$timestamp"
    mkdir -p "$backup_dir"
    
    # 检查是否有未提交的更改
    if git status --porcelain 2>/dev/null | grep -q .; then
        print_info "检测到本地修改，正在备份..."
        
        # 备份修改的文件
        git status --porcelain 2>/dev/null | while IFS= read -r line; do
            if [ -n "$line" ]; then
                status="${line:0:2}"
                file="${line:3}"
                
                # 只备份存在的文件
                if [ -f "$file" ]; then
                    dir=$(dirname "$file")
                    mkdir -p "$backup_dir/$dir"
                    cp "$file" "$backup_dir/$file/"
                    print_info "已备份: $file"
                fi
            fi
        done
        
        print_success "本地修改已备份到: ${GRAY}$backup_dir${NC}"
        print_info "如需恢复，请运行: ${GRAY}cp -r $backup_dir/* .${NC}"
    else
        print_info "没有检测到本地修改，跳过备份"
    fi
fi

# 清理本地未跟踪的文件
if [ "$CLEAN" = true ]; then
    echo ""
    echo -e "${BOLD}${YELLOW}🧹 清理本地未跟踪的文件...${NC}"
    
    # 显示将要删除的未跟踪文件
    untracked_files=$(git ls-files --others --exclude-standard)
    if [ -n "$untracked_files" ]; then
        print_info "将删除以下未跟踪的文件:"
        echo "$untracked_files" | sed 's/^/   /'
        
        # 确认是否删除
        should_clean=$FORCE
        if [ "$should_clean" = false ]; then
            echo -e "${YELLOW}❓ 确认删除这些文件? ${GRAY}(y/N):${NC} "
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY]) ]]; then
                should_clean=true
            fi
        fi
        
        if [ "$should_clean" = true ]; then
            # 删除未跟踪的文件
            git clean -fd -q
            print_success "已清理所有未跟踪的文件"
        else
            print_info "跳过清理操作"
        fi
    else
        print_info "没有未跟踪的文件，跳过清理"
    fi
fi

# 拉取最新更改
echo ""
echo -e "${BOLD}${BLUE}📥 拉取最新配置...${NC}"

# 确定是否要拉取
should_pull=$AUTO_PULL
if [ "$should_pull" = false ] && [ "$FORCE" = false ]; then
    echo -e "${YELLOW}❓ 是否从远程仓库拉取最新配置? ${GRAY}(Y/n):${NC} "
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY]|^$) ]]; then
        should_pull=true
    fi
fi

if [ "$should_pull" = true ]; then
    print_info "正在从远程仓库拉取最新配置..."
    
    # 先获取最新更改
    if git fetch origin "$current_branch"; then
        print_success "✓ 成功获取最新更改"
        
        # 检查是否有更新
        local_hash=$(git rev-parse HEAD)
        remote_hash=$(git rev-parse "origin/$current_branch")
        
        if [ "$local_hash" != "$remote_hash" ]; then
            print_info "检测到远程更新，正在合并..."
            
            # 尝试合并
            if git merge "origin/$current_branch"; then
                print_success "✓ 成功合并最新配置"
                
                # 显示更改摘要
                echo ""
                echo -e "${BOLD}${BLUE}📋 更新摘要:${NC}"
                echo -e "${GRAY}────────────────────────────────────────${NC}"
                
                # 显示最近提交的信息
                echo -e "${CYAN}最近提交:${NC}"
                git --no-pager log --oneline -5
                echo ""
                
                # 显示文件更改统计
                if git diff --stat HEAD~1 HEAD 2>/dev/null | grep -q .; then
                    echo -e "${CYAN}文件更改统计:${NC}"
                    git diff --stat HEAD~1 HEAD 2>/dev/null | sed 's/^/   /'
                    
                    # 检查extensions.list是否有更新
                    if git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -q "extensions.list"; then
                        echo ""
                        echo -e "${BOLD}${YELLOW}🔄 检测到扩展列表更新，正在同步扩展...${NC}"
                        
                        # 调用扩展同步脚本
                        sync_args=""
                        if [ "$FORCE" = true ]; then
                            sync_args="$sync_args --force"
                        fi
                        sync_args="$sync_args --mode $SYNC_MODE"
                        
                        # 运行同步脚本
                        if bash sync-extensions.sh $sync_args; then
                            print_success "✓ 扩展同步完成"
                        else
                            print_error "扩展同步失败"
                        fi
                    fi
                else
                    echo -e "${GREEN}没有文件更改${NC}"
                fi
            else
                print_error "✗ 合并失败，可能存在冲突"
                print_info "请手动解决冲突后重试"
                exit 1
            fi
        else
            print_info "本地配置已是最新，无需更新"
        fi
    else
        print_error "✗ 从远程仓库获取更改失败"
        print_info "请检查网络连接或远程仓库配置"
        exit 1
    fi
else
    print_info "⏭️  跳过拉取操作"
fi

# 完成信息
echo ""
echo -e "${BOLD}${GREEN}🎉 VSCode配置下载完成！${NC}"
echo -e "${GRAY}════════════════════════════════════════${NC}"

# 显示当前状态
echo -e "${BOLD}📊 当前仓库状态:${NC}"
if git status --short 2>/dev/null | grep -q .; then
    git status --short | while IFS= read -r line; do
        if [ -n "$line" ]; then
            echo -e "   ${GRAY}${line}${NC}"
        fi
    done
else
    echo -e "   ${GREEN}✓ 工作目录干净，没有未提交的更改${NC}"
fi

echo ""
echo -e "${GRAY}感谢使用VSCode配置下载脚本！${NC}"