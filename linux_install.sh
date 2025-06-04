#!/bin/bash

# 语言选项
echo "请选择语言 / Please select language:"
echo "1) 中文 (Chinese) "
echo "2) English"
read -p "输入选择 (Enter choice) [1/2]:  " lang_choice

# 根据用户选择设置语言
if [ "$lang_choice" -eq 1 ]; then
    export lang="zh"
    echo 'lang="zh"' >> /etc/environment
    install_condition="请使用root用户安装"
    prompt_clone_dir="请输入要克隆到的目录（默认是 /data）： "
    project_not_exist="项目目录不存在"
    clone_success="克隆成功"
    commands="可用命令: pictorialink init, pictorialink start, pictorialink stop, pictorialink restart, pictorialink dlmodels, pictorialink update, pictorialink logs, pictorialink status"
else
    export lang="en"
    echo 'lang="en"' >> /etc/environment
    install_condition="Please use the root user to install"
    prompt_clone_dir="Please enter the directory to clone to (default is /data): "
    project_not_exist="Project directory does not exist"
    clone_success="Clone successful"
    commands="Available commands: pictorialink init, pictorialink start, pictorialink stop, pictorialink restart, pictorialink dlmodels, pictorialink update, pictorialink logs, pictorialink status"
fi

echo "$install_condition"
read -p "$prompt_clone_dir" clone_dir


clone_dir=${clone_dir:-/data}
export CLONE_DIR="$clone_dir"


if [ ! -d "$clone_dir" ]; then
    mkdir -p "$clone_dir"
fi


if [ -d "$clone_dir/PictoEngine" ]; then
    cd "$clone_dir/PictoEngine" || { echo "$project_not_exist"; exit 1; }
    git pull origin main
else
    git clone https://github.com/pictorialink/PictoEngine.git "$clone_dir/PictoEngine"
    echo "$clone_success"
fi


cd "$clone_dir/PictoEngine" || { echo "$project_not_exist"; exit 1; }


chmod +x scripts/run_docker.sh


echo '#!/bin/bash' > /usr/local/bin/pictorialink
echo "bash \"$clone_dir/PictoEngine/scripts/run_docker.sh\" \"\$@\"" >> /usr/local/bin/pictorialink

chmod +x /usr/local/bin/pictorialink 


pictorialink init
pictorialink start 


echo "$commands"

