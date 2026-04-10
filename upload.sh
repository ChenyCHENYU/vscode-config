#!/bin/bash
###
 # @Author: ChenYu ycyplus@gmail.com
 # @Date: 2025-10-03 23:17:08
 # @LastEditors: ChenYu ycyplus@gmail.com
 # @LastEditTime: 2025-10-03 23:17:15
 # @FilePath: \vscode-config\upload.sh
 # @Description: 
 # Copyright (c) 2025 by CHENY, All Rights Reserved 😎. 
### 

# VSCode 配置快速上传脚本
# 这是一个简化的上传脚本，使用最常用的参数

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

"$SCRIPT_DIR/upload-config.sh" --auto-commit --auto-push --force --push-remotes origin,gitee