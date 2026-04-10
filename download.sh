#!/bin/bash
###
 # @Author: ChenYu ycyplus@gmail.com
 # @Date: 2025-10-03 23:17:33
 # @LastEditors: ChenYu ycyplus@gmail.com
 # @LastEditTime: 2025-10-03 23:17:40
 # @FilePath: \vscode-config\download.sh
 # @Description: 
 # Copyright (c) 2025 by CHENY, All Rights Reserved 😎. 
### 

# VSCode 配置快速下载脚本（覆盖模式）
# 这是一个简化的下载脚本，使用最常用的参数

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

"$SCRIPT_DIR/download-config.sh" --auto-pull --force --mode overwrite
"$SCRIPT_DIR/setup.sh" --force --silent --mode overwrite