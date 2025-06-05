#!/bin/bash


read -p "请输入您的 HOME 目录（默认是 $HOME）： " user_home
user_home=${user_home:-$HOME} 

run_command() {
    # Run command and check if successful
    "$@"
    if [ $? -ne 0 ]; then
        echo "Command failed: $*"
        exit 1
    fi
}

install_conda() {
    # Install Conda
    echo "Installing Conda..."
    if ! command -v conda &> /dev/null; then
        run_command curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
        run_command bash Miniconda3-latest-MacOSX-x86_64.sh -b -p "$user_home/miniconda3"  # 使用用户输入的 HOME
        export PATH="$user_home/miniconda3/bin:$PATH"
        echo "Conda installation completed"
    else
        echo "Conda is already installed"
    fi
}

create_conda_env() {
    # Create and activate Conda virtual environment
    echo "Creating Conda virtual environment..."
    run_command conda create -n comfyui_env python=3.10 wget git git-lfs -y
    source activate comfyui_env
}

clone_comfyui() {
    # Clone ComfyUI and install dependencies
    echo "Cloning comfyui..."
    target_dir="$user_home/ComfyUI"
    if [ ! -d "$target_dir" ]; then  # Check if directory exists
        mkdir "$target_dir"  # Create directory
    fi
    cd "$target_dir" || exit 1  # Change to ComfyUI directory
    run_command git clone https://github.com/comfyanonymous/ComfyUI.git .  # Clone to current directory
    echo "Installing comfyui dependencies..."
    run_command pip install -r requirements.txt
}

install_nodes() {
    # Install nodes based on custom_nodes.yml file
    if [ -f "docker/configs/custom_nodes.yml" ]; then
        nodes_config=$(cat docker/configs/custom_nodes.yml)
        # Here you can install nodes based on the content of nodes_config
        run_command python docker/scripts/install_nodes.py
    else
        echo "custom_nodes.yml file not found"
    fi
}

download_models() {
    # Download models based on custom_nodes.yml file
    if [ -f "docker/configs/custom_nodes.yml" ]; then
        run_command python scripts/download_models.py
    else
        echo "custom_nodes.yml file not found"
    fi
}

# Main execution
install_conda
create_conda_env
clone_comfyui
install_nodes
download_models
echo "Script execution completed"