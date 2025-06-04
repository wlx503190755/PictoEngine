import os
import subprocess
import sys
import yaml

def run_command(command):
    """运行命令并检查是否成功"""
    result = subprocess.run(command, shell=True)
    if result.returncode != 0:
        print(f"命令失败: {command}")
        sys.exit(1)

def install_conda():
    """安装 Conda"""
    print("正在安装 Conda...")
    if not shutil.which("conda"):
        run_command("curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh")
        run_command("bash Miniconda3-latest-MacOSX-x86_64.sh -b -p $HOME/miniconda3")
        os.environ["PATH"] = f"{os.path.expanduser('~')}/miniconda3/bin:" + os.environ["PATH"]
        print("Conda 安装完成")
    else:
        print("Conda 已安装")

def create_conda_env():
    """创建并激活 Conda 虚拟环境"""
    print("正在创建 Conda 虚拟环境...")
    run_command("conda create -n comfyui_env python=3.10 wget git git-lfs -y")
    run_command("source activate comfyui_env")

def clone_comfyui():
    """克隆 ComfyUI 并安装依赖"""
    print("正在克隆 comfyui...")
    run_command("git clone https://github.com/comfyanonymous/ComfyUI.git")
    os.chdir("ComfyUI")
    print("正在安装 comfyui 依赖...")
    run_command("pip install -r requirements.txt")

def install_nodes():
    """根据 custom_nodes.yml 文件安装节点"""
    if os.path.exists("docker/configs/custom_nodes.yml"):
        with open("docker/configs/custom_nodes.yml", 'r') as file:
            nodes_config = yaml.safe_load(file)
            # 这里可以根据 nodes_config 的内容进行节点安装
            run_command("python docker/scripts/install_nodes.py")
    else:
        print("未找到 custom_nodes.yml 文件")

def download_models():
    """根据 custom_nodes.yml 文件下载模型"""
    if os.path.exists("docker/configs/custom_nodes.yml"):
        run_command("python scripts/download_models.py")
    else:
        print("未找到 custom_nodes.yml 文件")

if __name__ == "__main__":
    install_conda()
    create_conda_env()
    clone_comfyui()
    install_nodes()
    download_models()
    print("脚本执行完成")