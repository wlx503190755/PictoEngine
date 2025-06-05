#!/bin/bash

# 语言选项
echo "请选择语言 / Please select language:"
echo "1) 中文 (Chinese) "
echo "2) English"
read -p "输入选择 (Enter choice) [1/2]:  " lang_choice

# 根据用户选择设置语言
if [ "$lang_choice" -eq 1 ]; then
    export lang="zh"
    install_condition="请使用root用户安装"
    prompt_clone_dir="请输入要克隆到的目录（默认是 /data）： "
    prompt_server_port="请输入服务端口（默认是 8188）： "
    project_not_exist="项目目录不存在"
    clone_success="克隆成功"
    server_start_success="服务已成功启动，请将如下地址填写至客户端：$server_url"
    commands="可用命令: pictorialink init, pictorialink start, pictorialink stop, pictorialink restart, pictorialink dlmodels, pictorialink update, pictorialink logs, pictorialink status"
elif [ "$input_choice" -eq 2 ]; then
    export lang="en"
    install_condition="Please use the root user to install"
    prompt_clone_dir="Please enter the directory to clone to (default is /data): "
    project_not_exist="Project directory does not exist"
    clone_success="Clone successful"
    commands="Available commands: pictorialink init, pictorialink start, pictorialink stop, pictorialink restart, pictorialink dlmodels, pictorialink update, pictorialink logs, pictorialink status"
else
    echo "输入无效，默认使用英语 / Invalid input, defaulting to English."
    export lang="en"
    install_condition="Please use the root user to install"
    prompt_clone_dir="Please enter the directory to clone to (default is /data): "
    prompt_server_port="Please enter the server port (default is 8188): "
    project_not_exist="Project directory does not exist"
    clone_success="Clone successful"
    server_start_success="Service has been started successfully, please fill the following address to the client: $server_url"
    commands="Available commands: pictorialink init, pictorialink start, pictorialink stop, pictorialink restart, pictorialink dlmodels, pictorialink update, pictorialink logs, pictorialink status"
fi

echo "$install_condition"
read -p "$prompt_server_port" server_port
read -p "$prompt_clone_dir" clone_dir

server_port=${server_port:-8188}
clone_dir=${clone_dir:-/data}
export CLONE_DIR="$clone_dir" server_port="$server_port" lang="$lang"

tee /etc/profile.d/custom_vars.sh >/dev/null <<EOF
#!/bin/sh
export CLONE_DIR="$clone_dir"
export server_port="$server_port"
export lang="$lang"
EOF

sudo chmod +x /etc/profile.d/custom_vars.sh
source /etc/profile

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

server_url=`ip -br addr show | awk -v port="${server_port}" '$2 == "UP" && !/lo|docker|virbr|veth|br-|tun|tap/ {split($3, a, "/"); print "http://" a[1] ":" port}' || echo "http://127.0.0.1:${server_port}"`

echo "$commands"
echo "$server_start_success"

