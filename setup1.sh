#!/bin/bash

# 获取 VSCode 用户配置目录
vscodeConfigDir="$HOME/.config/Code/User"

# 复制配置文件
cp "$(dirname "$0")/settings.json" "$vscodeConfigDir" -f
cp "$(dirname "$0")/keybindings.json" "$vscodeConfigDir" -f

# 复制扩展列表
cp "$(dirname "$0")/extensions.list" "$vscodeConfigDir" -f

# 安装扩展
while read -r extension; do
    code --install-extension "$extension"
done < "$(dirname "$0")/extensions.list"