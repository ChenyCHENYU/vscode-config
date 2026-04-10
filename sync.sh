#!/bin/bash
###
 # @Author: ChenYu ycyplus@gmail.com
 # @Date: 2025-10-03 23:18:23
 # @LastEditors: ChenYu ycyplus@gmail.com
 # @LastEditTime: 2025-10-03 23:18:29
 # @FilePath: \vscode-config\sync.sh
 # @Description: 
 # Copyright (c) 2025 by CHENY, All Rights Reserved 😎. 
### 

# VSCode 扩展快速同步脚本（覆盖模式）
# 这是一个简化的同步脚本，使用覆盖模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

"$SCRIPT_DIR/sync-extensions.sh" --force --mode overwrite