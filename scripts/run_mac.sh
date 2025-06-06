#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 语言设置
lang=${lang:-en}
CLONE_DIR=${CLONE_DIR:-"$HOME/ComfyUI"}


if [ "$lang" == "zh" ]; then
    INSTALL_START="开始安装 Conda..."
    INSTALL_SUCCESS="Conda 安装完成"
    INSTALL_FAILURE="Conda 安装失败"
    ACTIVATE_START="激活 Conda 环境..."
    ACTIVATE_SUCCESS="Conda 环境激活完成"
    ACTIVATE_FAILURE="Conda 环境激活失败"
    ENV_CREATE_START="创建 Conda 环境..."
    ENV_CREATE_SUCCESS="Conda 环境创建完成"
    CLONE_START="正在克隆 ComfyUI..."
    CLONE_SUCCESS="ComfyUI 克隆成功"
    CLONE_FAILURE="克隆 ComfyUI 失败"
    USAGE="用法: $0 {install|create_env|clone|start|stop|restart}"
    DIR_EMPTY="目录为空，正在克隆仓库..."
    DIR_NOT_EMPTY="正在拉取最新更改..."
else
    INSTALL_START="Starting Conda installation..."
    INSTALL_SUCCESS="Conda installation completed"
    INSTALL_FAILURE="Conda installation failed"
    ACTIVATE_START="Activating Conda environment..."
    ACTIVATE_SUCCESS="Conda environment activated"
    ACTIVATE_FAILURE="Conda environment activation failed"
    ENV_CREATE_START="Creating Conda environment..."
    ENV_CREATE_SUCCESS="Conda environment created"
    CLONE_START="Cloning ComfyUI..."
    CLONE_SUCCESS="ComfyUI cloned successfully"
    CLONE_FAILURE="Cloning ComfyUI failed"
    USAGE="Usage: $0 {install|create_env|clone|start|stop|restart}"
    DIR_EMPTY="Directory is empty, cloning repository..."
    DIR_NOT_EMPTY="Pulling latest changes..."
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

install_conda() {
    echo -e "${YELLOW}$INSTALL_START${NC}"
    if ! command -v conda &> /dev/null; then
        curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
        bash Miniconda3-latest-MacOSX-x86_64.sh -b -p "$HOME/miniconda3"
        export PATH="$HOME/miniconda3/bin:$PATH"
        echo -e "${GREEN}$INSTALL_SUCCESS${NC}"
    else
        echo "Conda is already installed, skipping installation."
    fi
}

create_conda_env() {
    echo -e "${YELLOW}$ENV_CREATE_START${NC}"
#    conda create -n comfyui_env python=3.10 wget git git-lfs -y
    conda init
    conda env create -f $PROJECT_ROOT/docker/configs/environment.yml -n pictoengine
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$ENV_CREATE_SUCCESS${NC}"
    else
        echo -e "${RED}$INSTALL_FAILURE${NC}"
        exit 1
    fi
}

activate_conda_env() {
    echo -e "${YELLOW}$ACTIVATE_START${NC}"
    source $HOME/.bash_profile  #和下面配置文件二选一，需要测试后确认
    source $HOME/.zshrc
    conda activate pictoengine    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$ACTIVATE_SUCCESS${NC}"
    else
        echo -e "${RED}$ACTIVATE_FAILURE${NC}"
        exit 1
    fi
}

clone_comfyui() {
    echo -e "${YELLOW}$CLONE_START${NC}"
    target_dir="$HOME/ComfyUI"
    
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    
    if [ "$(ls -A $target_dir)" ]; then
        echo "$DIR_NOT_EMPTY"
        cd "$target_dir"
        git pull
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$CLONE_SUCCESS${NC}"
        else
            echo -e "${RED}$CLONE_FAILURE${NC}"
            exit 1
        fi
    else
        echo "$DIR_EMPTY"
        cd "$target_dir"
        git clone --branch v0.3.34 https://github.com/comfyanonymous/ComfyUI.git .
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$CLONE_SUCCESS${NC}"
        else
            echo -e "${RED}$CLONE_FAILURE${NC}"
            exit 1
        fi
    fi
}

start_comfyui() {
    echo -e "${YELLOW}$START_START${NC}"
    activate_conda_env
    target_dir="$HOME/ComfyUI"
    python $target_dir/main.py --port 7860
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$START_SUCCESS${NC}"
    else
        echo -e "${RED}$START_FAILURE${NC}" 
        exit 1
    fi
}

stop_comfyui() {
    echo -e "${YELLOW}$STOP_START${NC}"
    target_dir="$HOME/ComfyUI"
    pkill -f "python $target_dir/main.py --port 7860"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$STOP_SUCCESS${NC}"
    else
        echo -e "${RED}$STOP_FAILURE${NC}" 
        exit 1
    fi
}

restart_comfyui() {
    stop_comfyui
    start_comfyui
}

#install_nodes() {
#    # Install nodes based on custom_nodes.yml file
#    if [ -f "$PROJECT_ROOT/docker/configs/custom_nodes.yml" ]; then
#        nodes_config=$(cat $PROJECT_ROOT/docker/configs/custom_nodes.yml)
#        # Here you can install nodes based on the content of nodes_config
#        run_command python $PROJECT_ROOT/docker/scripts/install_nodes.py
#    else
#        echo "custom_nodes.yml file not found"
#    fi
#}

download_models() {
  #  Download models based on custom_nodes.yml file
    if [ -f "$PROJECT_ROOT/docker/configs/custom_nodes.yml" ]; then
        python $PROJECT_ROOT/scripts/download_models.py
    else
        echo "custom_nodes.yml file not found"
    fi
}

main() {
    case "$1" in
        "init_conda")
            install_conda
            create_conda_env
            ;;
        "clone")
            clone_comfyui
            ;;
        "install_nodes")
            install_nodes
            ;;
        "download_models")
            download_models
            ;;
        "start")
            start_comfyui
            ;;
        "stop")
            stop_comfyui
            ;;
        "restart")
            restart_comfyui
            ;;
        *)
            echo "$USAGE"
            exit 1
            ;;
    esac
}

main "$@"