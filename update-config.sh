#!/bin/bash

# VSCode 配置更新脚本 - 优化版本
# 支持自动化Git操作，美化状态显示

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

# 美化Git状态显示
show_git_status() {
    local git_status=$(git status --porcelain 2>/dev/null)
    
    if [ -z "$git_status" ]; then
        print_info "工作目录干净，没有检测到更改"
        return 1
    fi
    
    echo ""
    echo -e "${BOLD}${BLUE}📋 检测到以下更改:${NC}"
    echo -e "${GRAY}────────────────────────────────────────${NC}"
    
    local added=0
    local modified=0
    local deleted=0
    local renamed=0
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then continue; fi
        
        local status="${line:0:2}"
        local file="${line:3}"
        local icon=""
        local color=""
        local action=""
        
        # 调试：打印原始Git状态（用于排查问题）
        # echo "DEBUG: 原始状态='$status', 文件='$file'" >&2
        
        case "$status" in
            "A ")  # 新增到暂存区
                icon="📄"
                color="${GREEN}"
                action="新增"
                added=$((added + 1))
                ;;
            " M")  # 工作目录中修改
                icon="📝"
                color="${YELLOW}" 
                action="修改"
                modified=$((modified + 1))
                ;;
            "M ")  # 暂存区中修改
                icon="📝"
                color="${YELLOW}" 
                action="修改"
                modified=$((modified + 1))
                ;;
            "MM")  # 暂存区和工作目录都修改
                icon="📝"
                color="${YELLOW}" 
                action="修改"
                modified=$((modified + 1))
                ;;
            " D")  # 工作目录中删除
                icon="🗑️ "
                color="${RED}"
                action="删除"
                deleted=$((deleted + 1))
                ;;
            "D ")  # 暂存区中删除
                icon="🗑️ "
                color="${RED}"
                action="删除"
                deleted=$((deleted + 1))
                ;;
            "AD")  # 新增后又删除
                icon="🗑️ "
                color="${RED}"
                action="删除"
                deleted=$((deleted + 1))
                ;;
            "MD")  # 修改后删除
                icon="🗑️ "
                color="${RED}"
                action="删除"
                deleted=$((deleted + 1))
                ;;
            "R ")  # 重命名
                icon="📋"
                color="${PURPLE}"
                action="重命名"
                renamed=$((renamed + 1))
                ;;
            "C ")  # 复制
                icon="📄"
                color="${BLUE}"
                action="复制"
                ;;
            "??")  # 未跟踪文件
                icon="❓"
                color="${CYAN}"
                action="未跟踪"
                ;;
            "!!")  # 忽略的文件
                icon="🚫"
                color="${GRAY}"
                action="忽略"
                ;;
            *)      # 其他未知状态
                icon="❔"
                color="${GRAY}"
                action="未知($status)"
                ;;
        esac
        
        # 格式化文件名
        local filename=$(basename "$file")
        local filepath=$(dirname "$file")
        
        if [ "$filepath" = "." ]; then
            filepath=""
        else
            filepath="${filepath}/"
        fi
        
        # 显示文件更改信息
        printf "${color}${icon} ${action}${NC} ${GRAY}${filepath}${NC}${BOLD}${filename}${NC}"
        
        # 根据不同状态显示相应的统计信息
        case "$status" in
            " M"|"M "|"MM")  # 只有修改的文件才显示差异统计
                if [ -f "$file" ]; then
                    local stat_info=$(git diff --stat HEAD -- "$file" 2>/dev/null | tail -n1)
                    if [[ "$stat_info" =~ ([0-9]+)\ insertion.*([0-9]+)\ deletion ]]; then
                        local insertions="${BASH_REMATCH[1]}"
                        local deletions="${BASH_REMATCH[2]}"
                        printf " ${GRAY}(${GREEN}+${insertions}${GRAY}/${RED}-${deletions}${GRAY})${NC}"
                    elif [[ "$stat_info" =~ ([0-9]+)\ insertion ]]; then
                        local insertions="${BASH_REMATCH[1]}"
                        printf " ${GRAY}(${GREEN}+${insertions}${GRAY})${NC}"
                    elif [[ "$stat_info" =~ ([0-9]+)\ deletion ]]; then
                        local deletions="${BASH_REMATCH[1]}"
                        printf " ${GRAY}(${RED}-${deletions}${GRAY})${NC}"
                    fi
                fi
                ;;
            "A ")  # 新增文件显示行数
                if [ -f "$file" ]; then
                    local line_count=$(wc -l < "$file" 2>/dev/null || echo "0")
                    printf " ${GRAY}(${line_count} 行)${NC}"
                fi
                ;;
            " D"|"D "|"AD"|"MD")  # 删除文件不显示任何统计
                # 删除的文件什么都不显示，保持简洁
                ;;
            "??")  # 未跟踪文件显示大小
                if [ -f "$file" ]; then
                    local file_size=$(ls -lh "$file" 2>/dev/null | awk '{print $5}' || echo "0B")
                    printf " ${GRAY}(${file_size})${NC}"
                fi
                ;;
            "R "|"C ")  # 重命名/复制不显示统计
                ;;
        esac
        
        echo ""
    done <<< "$git_status"
    
    echo -e "${GRAY}────────────────────────────────────────${NC}"
    
    # 显示统计信息
    local total=$((added + modified + deleted + renamed))
    echo -e "${BOLD}📊 更改统计:${NC} "
    
    local stats=""
    if [ $added -gt 0 ]; then
        stats="${stats}${GREEN}新增 ${added}${NC} "
    fi
    if [ $modified -gt 0 ]; then
        stats="${stats}${YELLOW}修改 ${modified}${NC} "
    fi
    if [ $deleted -gt 0 ]; then
        stats="${stats}${RED}删除 ${deleted}${NC} "
    fi
    if [ $renamed -gt 0 ]; then
        stats="${stats}${PURPLE}重命名 ${renamed}${NC} "
    fi
    
    echo -e "   ${stats}${GRAY}(共 ${total} 个文件)${NC}"
    echo ""
    
    return 0
}

# 显示提交信息
show_commit_info() {
    local commit_message="$1"
    echo ""
    echo -e "${BOLD}${BLUE}📝 准备提交:${NC}"
    echo -e "   ${GRAY}消息:${NC} ${commit_message}"
    echo -e "   ${GRAY}时间:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "   ${GRAY}分支:${NC} $(git branch --show-current 2>/dev/null || echo 'main')"
}

# 显示推送信息
show_push_info() {
    local remotes=("$@")
    local current_branch=$(git branch --show-current 2>/dev/null || echo "main")
    
    echo ""
    echo -e "${BOLD}${BLUE}🚀 准备推送到远程仓库:${NC}"
    for remote in "${remotes[@]}"; do
        if git remote get-url "$remote" &>/dev/null; then
            local url=$(git remote get-url "$remote" 2>/dev/null)
            echo -e "   ${GREEN}✓${NC} ${remote} → ${current_branch} ${GRAY}(${url})${NC}"
        else
            echo -e "   ${RED}✗${NC} ${remote} ${GRAY}(不存在)${NC}"
        fi
    done
}

# 参数解析
AUTO_COMMIT=false
AUTO_PUSH=false
FORCE=false
COMMIT_MESSAGE="配置更新"
PUSH_REMOTES=("origin")

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-commit)
            AUTO_COMMIT=true
            shift
            ;;
        --auto-push)
            AUTO_PUSH=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --commit-message)
            COMMIT_MESSAGE="$2"
            shift 2
            ;;
        --push-remotes)
            IFS=',' read -ra PUSH_REMOTES <<< "$2"
            shift 2
            ;;
        --help)
            echo -e "${BOLD}VSCode配置更新脚本${NC}"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --auto-commit          自动提交更改"
            echo "  --auto-push            自动推送更改"
            echo "  --force                强制执行，无交互"
            echo "  --commit-message MSG   自定义提交消息"
            echo "  --push-remotes LIST    远程仓库列表(用逗号分隔)"
            echo ""
            echo "示例:"
            echo "  $0 --auto-commit --auto-push --force --push-remotes origin,gitee"
            echo "  $0 --commit-message \"重要更新\" --auto-commit"
            exit 0
            ;;
        *)
            print_error "未知参数: $1"
            exit 1
            ;;
    esac
done

# 主程序开始
echo -e "${BOLD}${CYAN}🚀 VSCode配置更新脚本${NC}"
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

# 检查VSCode是否安装
if ! command -v code &> /dev/null; then
    print_error "VSCode未安装或未添加到PATH中。请先安装VSCode。"
    exit 1
fi

# 确定操作系统和VSCode配置目录
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

print_info "操作系统: ${BOLD}$OS_TYPE${NC}"
print_info "VSCode配置目录: ${GRAY}$VSCODE_CONFIG_DIR${NC}"

# 检查VSCode配置目录是否存在
if [ ! -d "$VSCODE_CONFIG_DIR" ]; then
    print_error "VSCode配置目录不存在: $VSCODE_CONFIG_DIR"
    exit 1
fi

echo ""
echo -e "${BOLD}${YELLOW}📂 开始更新配置文件...${NC}"

# 更新settings.json
if [ -f "$VSCODE_CONFIG_DIR/settings.json" ]; then
    print_info "更新 ${BOLD}settings.json${NC}"
    cp "$VSCODE_CONFIG_DIR/settings.json" .
    print_success "✓ settings.json 已更新"
else
    print_warning "VSCode settings.json 不存在，跳过更新"
fi

# 更新keybindings.json
if [ -f "$VSCODE_CONFIG_DIR/keybindings.json" ]; then
    print_info "更新 ${BOLD}keybindings.json${NC}"
    cp "$VSCODE_CONFIG_DIR/keybindings.json" .
    print_success "✓ keybindings.json 已更新"
else
    print_warning "VSCode keybindings.json 不存在，跳过更新"
fi

# 更新代码片段
if [ -d "$VSCODE_CONFIG_DIR/snippets" ]; then
    print_info "更新 ${BOLD}代码片段${NC}"
    
    # 确保snippets目录存在
    mkdir -p snippets
    
    # 清空现有代码片段目录
    rm -rf snippets/*
    
    # 复制所有代码片段
    if cp -r "$VSCODE_CONFIG_DIR/snippets/"* snippets/ 2>/dev/null; then
        snippet_count=$(find snippets -type f | wc -l)
        print_success "✓ 代码片段已更新 (${snippet_count} 个文件)"
    else
        print_warning "没有找到代码片段，snippets目录为空"
    fi
else
    print_warning "VSCode snippets 目录不存在，跳过更新代码片段"
    mkdir -p snippets
fi

# 更新扩展列表
print_info "更新 ${BOLD}扩展列表${NC}"
if extensions=$(code --list-extensions 2>/dev/null); then
    # 创建带有注释头的新扩展列表
    {
        echo "# VSCode 扩展列表"
        echo "# 此文件由update脚本自动生成"
        echo "# 更新时间: $(date)"
        echo "# 操作系统: $OS_TYPE"
        echo "#"
        echo "# 每行一个扩展ID"
        echo ""
        echo "$extensions"
    } > extensions.list
    
    extension_count=$(echo "$extensions" | wc -l)
    print_success "✓ 扩展列表已更新 (${extension_count} 个扩展)"
else
    print_warning "未找到已安装的扩展或获取扩展列表失败"
fi

# Git操作
echo ""
echo -e "${BOLD}${PURPLE}🔍 检查Git状态...${NC}"

if show_git_status; then
    # 确定是否要提交
    should_commit=$AUTO_COMMIT
    if [ "$should_commit" = false ] && [ "$FORCE" = false ]; then
        echo -e "${YELLOW}❓ 是否提交更改? ${GRAY}(Y/n):${NC} " 
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY]|^$) ]]; then
            should_commit=true
        fi
    fi
    
    if [ "$should_commit" = true ]; then
        # 显示提交信息
        full_commit_message="$COMMIT_MESSAGE - $(date '+%Y-%m-%d %H:%M:%S')"
        show_commit_info "$full_commit_message"
        
        # 执行 git add
        print_info "添加更改到暂存区..."
        if git add .; then
            # 执行 git commit
            print_info "提交更改..."
            if git commit -m "$full_commit_message"; then
                print_success "✓ 更改已成功提交"
                
                # 确定是否要推送
                should_push=$AUTO_PUSH
                if [ "$should_push" = false ] && [ "$FORCE" = false ]; then
                    echo ""
                    echo -e "${YELLOW}❓ 是否推送到远程仓库? ${GRAY}(Y/n):${NC} "
                    read -r response
                    if [[ "$response" =~ ^([yY][eE][sS]|[yY]|^$) ]]; then
                        should_push=true
                    fi
                fi
                
                if [ "$should_push" = true ]; then
                    # 显示推送信息
                    show_push_info "${PUSH_REMOTES[@]}"
                    
                    # 获取当前分支
                    current_branch=$(git branch --show-current 2>/dev/null || echo "main")
                    
                    # 推送到各个远程仓库
                    push_success=true
                    echo ""
                    for remote in "${PUSH_REMOTES[@]}"; do
                        print_info "推送到 ${BOLD}${remote}${NC} → ${current_branch}"
                        
                        # 检查远程仓库是否存在
                        if git remote get-url "$remote" &>/dev/null; then
                            if git push "$remote" "$current_branch"; then
                                print_success "✓ 成功推送到 ${remote}"
                            else
                                print_error "✗ 推送到 ${remote} 失败"
                                push_success=false
                            fi
                        else
                            print_warning "⚠ 远程仓库 '${remote}' 不存在，跳过推送"
                        fi
                    done
                    
                    if [ "$push_success" = true ]; then
                        print_success "🎉 所有推送操作完成"
                    fi
                else
                    print_info "⏭️  跳过推送操作。请手动推送: ${GRAY}git push${NC}"
                fi
            else
                print_error "git commit 失败"
                exit 1
            fi
        else
            print_error "git add 失败"
            exit 1
        fi
    else
        print_info "⏭️  跳过Git提交操作"
    fi
fi

# 完成信息
echo ""
echo -e "${BOLD}${GREEN}🎉 VSCode配置更新完成！${NC}"
echo -e "${GRAY}════════════════════════════════════════${NC}"

# 显示最终Git状态
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

current_branch=$(git branch --show-current 2>/dev/null)
if [ -n "$current_branch" ]; then
    echo -e "${BOLD}🌿 当前分支:${NC} ${current_branch}"
fi

echo ""
echo -e "${GRAY}感谢使用VSCode配置更新脚本！${NC}"