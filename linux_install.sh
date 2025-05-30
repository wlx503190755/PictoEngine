#!/bin/bash

# 提示用户输入克隆目录
read -p "请输入要克隆到的目录（默认是 /data/）： " clone_dir

# 如果用户没有输入，则使用 /data/
clone_dir=${clone_dir:-/data/}
export CLONE_DIR="$clone_dir"

# 创建目录（如果不存在）
mkdir -p "$clone_dir"

# 克隆项目代码
git clone https://github.com/pictorialink/PictoEngine.git "$clone_dir"

# 进入项目目录
cd "$clone_dir/PictoEngine" || { echo "项目目录不存在"; exit 1; }

# 修改脚本权限
chmod +x scripts/run_docker.sh

# 添加别名到 ~/.bashrc 或 ~/.bash_profile
echo "alias pictorialink='$(pwd)/scripts/run_docker.sh'" >> ~/.bashrc

# 使别名生效
source ~/.bashrc

# 运行初始化和启动命令
pictorialink init
pictorialink start 
