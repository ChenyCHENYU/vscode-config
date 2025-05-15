# VSCode 配置更新脚本 - Windows版本
# 此脚本用于管理员从本地VSCode配置更新到仓库

# 设置控制台颜色函数
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Info" {
            Write-Host "[INFO] $Message" -ForegroundColor Green
        }
        "Warning" {
            Write-Host "[WARNING] $Message" -ForegroundColor Yellow
        }
        "Error" {
            Write-Host "[ERROR] $Message" -ForegroundColor Red
        }
    }
}

# 检查Git是否安装
try {
    $null = Get-Command git -ErrorAction Stop
}
catch {
    Write-ColorMessage "Git未安装。请先安装Git。" -Type "Error"
    exit 1
}

# 检查是否在Git仓库中
$isGitRepo = git rev-parse --is-inside-work-tree 2>$null
if (-not $isGitRepo) {
    Write-ColorMessage "当前目录不是Git仓库。请在VSCode配置仓库目录中运行此脚本。" -Type "Error"
    exit 1
}

# 确定VSCode配置目录
$VSCODE_CONFIG_DIR = "$env:APPDATA\Code\User"
Write-ColorMessage "VSCode配置目录: $VSCODE_CONFIG_DIR"

# 检查VSCode配置目录是否存在
if (-not (Test-Path $VSCODE_CONFIG_DIR)) {
    Write-ColorMessage "VSCode配置目录不存在: $VSCODE_CONFIG_DIR" -Type "Error"
    exit 1
}

# 更新settings.json
if (Test-Path "$VSCODE_CONFIG_DIR\settings.json") {
    Write-ColorMessage "更新 settings.json"
    Copy-Item "$VSCODE_CONFIG_DIR\settings.json" "." -Force
}
else {
    Write-ColorMessage "VSCode settings.json 不存在，跳过更新" -Type "Warning"
}

# 更新keybindings.json
if (Test-Path "$VSCODE_CONFIG_DIR\keybindings.json") {
    Write-ColorMessage "更新 keybindings.json"
    Copy-Item "$VSCODE_CONFIG_DIR\keybindings.json" "." -Force
}
else {
    Write-ColorMessage "VSCode keybindings.json 不存在，跳过更新" -Type "Warning"
}

# 更新代码片段
if (Test-Path "$VSCODE_CONFIG_DIR\snippets") {
    Write-ColorMessage "更新代码片段"
    
    # 确保snippets目录存在
    if (-not (Test-Path "snippets")) {
        New-Item -ItemType Directory -Path "snippets" -Force | Out-Null
    }
    
    # 清空现有代码片段目录（避免保留已删除的片段）
    Remove-Item "snippets\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # 复制所有代码片段
    Copy-Item "$VSCODE_CONFIG_DIR\snippets\*" "snippets\" -Recurse -Force -ErrorAction SilentlyContinue
    
    # 检查是否有代码片段被复制
    if (Get-ChildItem -Path "snippets" -ErrorAction SilentlyContinue) {
        Write-ColorMessage "代码片段已更新"
    }
    else {
        Write-ColorMessage "没有找到代码片段，snippets目录为空" -Type "Warning"
    }
}
else {
    Write-ColorMessage "VSCode snippets 目录不存在，跳过更新代码片段" -Type "Warning"
    # 创建snippets目录以备将来使用
    if (-not (Test-Path "snippets")) {
        New-Item -ItemType Directory -Path "snippets" -Force | Out-Null
    }
}

# 更新扩展列表
Write-ColorMessage "更新扩展列表"
$extensions = code --list-extensions

# 创建带有注释头的新扩展列表
$header = @"
# VSCode 扩展列表
# 此文件由update-config.ps1脚本自动生成
# 更新时间: $(Get-Date)
#
# 每行一个扩展ID

"@

# 将注释头和扩展列表写入文件
Set-Content -Path "extensions.list" -Value $header
Add-Content -Path "extensions.list" -Value $extensions

Write-ColorMessage "配置更新完成！"
Write-ColorMessage "请检查更改，然后使用Git提交并推送更改："
Write-Host "  git add ."
Write-Host "  git commit -m ""更新VSCode配置"""
Write-Host "  git push"

# 等待用户按任意键继续
Write-Host "`n按任意键继续..." -NoNewline
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")