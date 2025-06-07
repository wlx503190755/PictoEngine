#!/bin/bash

# 语言选项
echo "请选择语言 / Please select language:"
echo "1) 中文 (Chinese) "
echo "2) English"
read -p "输入选择 (Enter choice) [1/2]:  " lang_choice

# 根据用户选择设置语言
if [ "$lang_choice" -eq 1 ]; then
    export lang="zh"
    prompt_server_port="请输入服务端口（默认是 8188）： "
    project_not_exist="项目目录不存在"
    clone_success="克隆成功"
    commands="可用命令: pictorialink init, pictorialink start, pictorialink stop, pictorialink restart, pictorialink dlmodels, pictorialink update, pictorialink logs, pictorialink status"
elif [ "$input_choice" -eq 2 ]; then
    export lang="en"
    project_not_exist="Project directory does not exist"
    clone_success="Clone successful"
    commands="Available commands: pictorialink init, pictorialink start, pictorialink stop, pictorialink restart, pictorialink dlmodels, pictorialink update, pictorialink logs, pictorialink status"
else
    echo "输入无效，默认使用英语 / Invalid input, defaulting to English."
    export lang="en"
    prompt_server_port="Please enter the server port (default is 8188): "
    project_not_exist="Project directory does not exist"
    clone_success="Clone successful"
    commands="Available commands: pictorialink init, pictorialink start, pictorialink stop, pictorialink restart, pictorialink dlmodels, pictorialink update, pictorialink logs, pictorialink status"
fi

read -p "$prompt_server_port" server_port
server_port=${server_port:-8188}
export server_port="$server_port" lang="$lang"

if [ -d "$HOME/PictoEngine" ]; then
    cd "$HOME/PictoEngine" || { echo "$project_not_exist"; exit 1; }
    git pull origin main
else
    git clone https://github.com/pictorialink/PictoEngine.git "$HOME/PictoEngine"
    echo "$clone_success"
fi

cd "$HOME/PictoEngine" || { echo "$project_not_exist"; exit 1; }

chmod +x scripts/run_mac.sh

# 目标目录
BIN_DIR="/usr/local/bin"

# 判断目录是否存在
if [ ! -d "$BIN_DIR" ]; then
    echo "目录不存在，正在创建 $BIN_DIR ..."
    sudo mkdir -p "$BIN_DIR"  # 使用 -p 选项以确保创建父目录
else
    echo "目录 $BIN_DIR 已存在，直接继续 ..."
fi

# 继续执行下一步
# 例如，创建脚本文件
echo '#!/bin/bash' | sudo tee "$BIN_DIR/pictorialink"
echo "bash \"$HOME/PictoEngine/scripts/run_mac.sh\" \"\$@\"" | sudo tee -a "$BIN_DIR/pictorialink"
sudo chmod +x "$BIN_DIR/pictorialink"

sudo chmod +x $BIN_DIR/pictorialink && source ~/.zshrc
pictorialink init
pictorialink start 

echo "$commands"
