#!/bin/bash
###
 # @Author: ChenYu ycyplus@gmail.com
 # @Date: 2025-10-03 23:17:59
 # @LastEditors: ChenYu ycyplus@gmail.com
 # @LastEditTime: 2025-10-03 23:18:05
 # @FilePath: \vscode-config\download-extend.sh
 # @Description: 
 # Copyright (c) 2025 by CHENY, All Rights Reserved 😎. 
### 

# VSCode 配置快速下载脚本（扩展模式）
# 这是一个简化的下载脚本，使用扩展模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

"$SCRIPT_DIR/download-config.sh" --auto-pull --force --mode extend
"$SCRIPT_DIR/setup.sh" --force --silent --mode extend