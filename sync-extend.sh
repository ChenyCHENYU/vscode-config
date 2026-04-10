#!/bin/bash
###
 # @Author: ChenYu ycyplus@gmail.com
 # @Date: 2025-10-03 23:18:48
 # @LastEditors: ChenYu ycyplus@gmail.com
 # @LastEditTime: 2025-10-03 23:18:54
 # @FilePath: \vscode-config\sync-extend.sh
 # @Description: 
 # Copyright (c) 2025 by CHENY, All Rights Reserved 😎. 
### 

# VSCode 扩展快速同步脚本（扩展模式）
# 这是一个简化的同步脚本，使用扩展模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

"$SCRIPT_DIR/sync-extensions.sh" --force --mode extend