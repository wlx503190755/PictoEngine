#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 变量设置
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
lang=${lang:-en}
export CLONE_DIR="$HOME/ComfyUI"
export VENV_DIR=""
export CONFIG_DIR="$PROJECT_ROOT/docker/configs"
export COMFYUI_BRANCH="v0.3.34"

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
    START_START="启动comfyui服务"
    START_SUCCESS="comfyui 启动成功"
    START_FAILURE="comfyui 启动失败"
    STOP_START="关闭comfyui服务"
    STOP_SUCCESS="comfyui 已关闭"
    STOP_FAILURE="comfyui 停止失败"
    INSTALL_NODES_SUCCESS="节点安装成功"
    INSTALL_NODES_FAILURE="节点安装失败"
    DOWNLOAD_MODELS_SUCCESS="模型下载成功"
    DOWNLOAD_MODELS_FAILURE="模型下载失败"
    USAGE="用法: $0 {init_conda|init_comfyui|install_nodes|download_models|start|stop|restart}"
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
    START_START="Comfyui start"
    START_SUCCESS="Comyui start successfully"
    START_FAILURE="Comyui start failed"
    STOP_START=""
    STOP_SUCCESS=""
    STOP_FAILURE=""
    INSTALL_NODES_SUCCESS=
    INSTALL_NODES_FAILURE=
    DOWNLOAD_MODELS_SUCCESS=
    DOWNLOAD_MODELS_FAILURE=
    USAGE="Usage: $0 {init_conda|init_comfyui|install_nodes|download_models|start|stop|restart}"
    DIR_EMPTY="Directory is empty, cloning repository..."
    DIR_NOT_EMPTY="Pulling latest changes..."
fi



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
    conda init
    conda create -n pictoengine python=3.10 wget git git-lfs -y
 #   conda env create -f $PROJECT_ROOT/docker/configs/environment.yml -n pictoengine
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$ENV_CREATE_SUCCESS${NC}"
 #       conda env config vars set server_port="$server_port"
    else
        echo -e "${RED}$INSTALL_FAILURE${NC}"
        exit 1
    fi
}

activate_conda_env() {
    echo -e "${YELLOW}$ACTIVATE_START${NC}"
    source $HOME/.bash_profile  #和下面配置文件二选一，需要测试后确认
#    source $HOME/.zshrc
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
    activate_conda_env
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    
    if [ "$(ls -A $target_dir)" ]; then
        echo "$DIR_NOT_EMPTY"
        cd "$target_dir"
        # 拉取指定分支的最新更新
        git fetch origin
        git checkout $COMFYUI_BRANCH
        git pull origin $COMFYUI_BRANCH
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$CLONE_SUCCESS${NC}"
            pip install --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cpu
            pip install -r $target_dir/requirements.txt
            git clone --recursive https://github.com/dmlc/decord.git
            cd decord && mkdir build && cd build
            cmake .. -DUSE_METAL=ON
            make -j$(sysctl -n hw.ncpu)
            cd ../python && pip install -e .
        else
            echo -e "${RED}$CLONE_FAILURE${NC}"
            exit 1
        fi
    else
        echo "$DIR_EMPTY"
        cd "$target_dir" 
        git clone --branch $COMFYUI_BRANCH https://github.com/comfyanonymous/ComfyUI.git .
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$CLONE_SUCCESS${NC}"
            pip install --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cpu
            pip install -r $target_dir/requirements.txt
            git clone --recursive https://github.com/dmlc/decord.git
            cd decord && mkdir build && cd build
            cmake .. -DUSE_METAL=ON
            make -j$(sysctl -n hw.ncpu)
            cd ../python && pip install -e .
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
    nohup python $target_dir/main.py --port ${server_port} > $target_dir/comfyui.log 2>&1 &
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
    pkill -f "python $target_dir/main.py --port ${server_port}"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$STOP_SUCCESS${NC}"
        truncate -s 0 $target_dir/comfyui.log
    else
        echo -e "${RED}$STOP_FAILURE${NC}" 
        exit 1
    fi
}

restart_comfyui() {
    stop_comfyui
    start_comfyui
}

log_view()  {
    target_dir="$HOME/ComfyUI"
    tail -500f $target_dir/comfyui.log
}

install_nodes() {
    activate_conda_env
    if [ -f "$PROJECT_ROOT/docker/configs/custom_nodes.yml" ]; then
        python $PROJECT_ROOT/docker/scripts/install_nodes.py
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$INSTALL_NODES_SUCCESS${NC}"
        else
            echo -e "${RED}$INSTALL_NODES_FAILURE${NC}"
            exit 1
        fi
    else
        echo -e "${RED}$INSTALL_NODES_FAILURE${NC}"
        exit 1
    fi
}

download_models() {
  #  Download models based on custom_nodes.yml file
    activate_conda_env
    if [ -f "$PROJECT_ROOT/docker/configs/custom_nodes.yml" ]; then
        python $PROJECT_ROOT/scripts/download_models.py
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$DOWNLOAD_MODELS_SUCCESS${NC}"
        else
            echo -e "${RED}$DOWNLOAD_MODELS_FAILURE${NC}"
            exit 1
        fi
    else
        echo -e "${RED}$DOWNLOAD_MODELS_FAILURE${NC}"
        exit 1
    fi
}

main() {
    case "$1" in
        "init")
            install_conda
            create_conda_env
            clone_comfyui
            install_nodes
            download_models
            ;;
        "init_comfyui")
            clone_comfyui
            ;;
        "install_nodes")
            install_nodes
            ;;
        "dlmodels")
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
        "logs")
            log_view
            ;;
        *)
            echo "$USAGE"
            exit 1
            ;;
    esac
}

main "$@"
