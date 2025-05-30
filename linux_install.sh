#!/bin/bash

# 提示用户输入克隆目录
read -p "请输入要克隆到的目录（默认是 /data）： " clone_dir

# 如果用户没有输入，则使用 /data/
clone_dir=${clone_dir:-/data}
export CLONE_DIR="$clone_dir"

# 创建目录（如果不存在）
if [ ! -d "$clone_dir" ]; then
    mkdir -p "$clone_dir"
fi
# 克隆项目代码
if [ -d "$clone_dir/PictoEngine" ]; then
    cd "$clone_dir/PictoEngine" || { echo "项目目录不存在"; exit 1; }
    git pull origin main
else
    git clone https://github.com/pictorialink/PictoEngine.git "$clone_dir"
fi

# 创建一个新的脚本文件
echo '#!/bin/bash' > /usr/local/bin/pictorialink
echo 'bash /path/to/PictoEngine/scripts/run_docker.sh "$@"' >> /usr/local/bin/pictorialink

# 使新脚本可执行
chmod +x /usr/local/bin/pictorialink 

# 添加别名到 ~/.bashrc 或 ~/.bash_profile
if ! grep -q "alias pictorialink=" /etc/profile; then
    echo "alias pictorialink='$(pwd)/scripts/run_docker.sh'" >> /etc/profile
fi
# 使别名生效
source /etc/profile

# 运行初始化和启动命令
pictorialink init
pictorialink start 
