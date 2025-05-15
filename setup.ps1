# VSCode 配置安装脚本 - Windows版本
# 此脚本用于安装团队标准的VSCode配置

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

# 检查是否以管理员权限运行
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-ColorMessage "建议使用管理员权限运行此脚本以确保所有功能正常工作。" -Type "Warning"
}

# 检查VSCode是否安装
try {
    $null = Get-Command code -ErrorAction Stop
}
catch {
    Write-ColorMessage "VSCode未安装或未添加到PATH中。请先安装VSCode。" -Type "Error"
    exit 1
}

# 确定VSCode配置目录
$VSCODE_CONFIG_DIR = "$env:APPDATA\Code\User"
Write-ColorMessage "VSCode配置目录: $VSCODE_CONFIG_DIR"

# 创建配置目录（如果不存在）
if (-not (Test-Path $VSCODE_CONFIG_DIR)) {
    New-Item -ItemType Directory -Path $VSCODE_CONFIG_DIR -Force | Out-Null
}
if (-not (Test-Path "$VSCODE_CONFIG_DIR\snippets")) {
    New-Item -ItemType Directory -Path "$VSCODE_CONFIG_DIR\snippets" -Force | Out-Null
}

# 备份现有配置
$BACKUP_DIR = "$VSCODE_CONFIG_DIR\backup_$(Get-Date -Format 'yyyyMMddHHmmss')"
Write-ColorMessage "备份现有配置到: $BACKUP_DIR"
New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
New-Item -ItemType Directory -Path "$BACKUP_DIR\snippets" -Force | Out-Null

# 备份settings.json
if (Test-Path "$VSCODE_CONFIG_DIR\settings.json") {
    Copy-Item "$VSCODE_CONFIG_DIR\settings.json" "$BACKUP_DIR\"
}

# 备份keybindings.json
if (Test-Path "$VSCODE_CONFIG_DIR\keybindings.json") {
    Copy-Item "$VSCODE_CONFIG_DIR\keybindings.json" "$BACKUP_DIR\"
}

# 备份代码片段
if (Test-Path "$VSCODE_CONFIG_DIR\snippets") {
    Copy-Item "$VSCODE_CONFIG_DIR\snippets\*" "$BACKUP_DIR\snippets\" -Recurse -Force -ErrorAction SilentlyContinue
}

# 复制配置文件
Write-ColorMessage "安装配置文件..."

# 复制settings.json
Copy-Item "settings.json" "$VSCODE_CONFIG_DIR\" -Force
Write-ColorMessage "已安装 settings.json"

# 复制keybindings.json
Copy-Item "keybindings.json" "$VSCODE_CONFIG_DIR\" -Force
Write-ColorMessage "已安装 keybindings.json"

# 复制代码片段
if (Test-Path "snippets") {
    Copy-Item "snippets\*" "$VSCODE_CONFIG_DIR\snippets\" -Recurse -Force
    Write-ColorMessage "已安装代码片段"
}
else {
    Write-ColorMessage "未找到代码片段目录，跳过安装代码片段" -Type "Warning"
    # 创建snippets目录以备将来使用
    New-Item -ItemType Directory -Path "snippets" -Force | Out-Null
}

# 安装扩展
if (Test-Path "extensions.list") {
    Write-ColorMessage "开始安装扩展..."
    
    # 统计扩展总数
    $extensions = Get-Content "extensions.list" | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' }
    $TOTAL_EXTENSIONS = $extensions.Count
    $INSTALLED = 0
    
    # 读取并安装扩展
    foreach ($extension in $extensions) {
        $INSTALLED++
        Write-ColorMessage "安装扩展 ($INSTALLED/$TOTAL_EXTENSIONS): $extension"
        code --install-extension $extension --force
    }
    
    Write-ColorMessage "扩展安装完成: $INSTALLED/$TOTAL_EXTENSIONS"
}
else {
    Write-ColorMessage "未找到extensions.list文件，跳过安装扩展" -Type "Warning"
}

Write-ColorMessage "VSCode配置安装完成！"
Write-ColorMessage "如果您需要恢复之前的配置，备份文件位于: $BACKUP_DIR"

# 等待用户按任意键继续
Write-Host "`n按任意键继续..." -NoNewline
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")