import os
import subprocess
import sys
import yaml

def run_command(command):
    """Run command and check if successful"""
    result = subprocess.run(command, shell=True)
    if result.returncode != 0:
        print(f"Command failed: {command}")
        sys.exit(1)

def install_conda():
    """Install Conda"""
    print("Installing Conda...")
    if not shutil.which("conda"):
        run_command("curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh")
        run_command("bash Miniconda3-latest-MacOSX-x86_64.sh -b -p $HOME/miniconda3")
        os.environ["PATH"] = f"{os.path.expanduser('~')}/miniconda3/bin:" + os.environ["PATH"]
        print("Conda installation completed")
    else:
        print("Conda is already installed")

def create_conda_env():
    """Create and activate Conda virtual environment"""
    print("Creating Conda virtual environment...")
    run_command("conda create -n comfyui_env python=3.10 wget git git-lfs -y")
    run_command("source activate comfyui_env")

def clone_comfyui():
    """Clone ComfyUI and install dependencies"""
    print("Cloning comfyui...")
    target_dir = "ComfyUI"  # Target directory
    if not os.path.exists(target_dir):  # Check if directory exists
        os.makedirs(target_dir)  # Create directory
    os.chdir(target_dir)  # Change to ComfyUI directory
    run_command("git clone https://github.com/comfyanonymous/ComfyUI.git .")  # Clone to current directory
    print("Installing comfyui dependencies...")
    run_command("pip install -r requirements.txt")

def install_nodes():
    """Install nodes based on custom_nodes.yml file"""
    if os.path.exists("docker/configs/custom_nodes.yml"):
        with open("docker/configs/custom_nodes.yml", 'r') as file:
            nodes_config = yaml.safe_load(file)
            # Here you can install nodes based on the content of nodes_config
            run_command("python docker/scripts/install_nodes.py")
    else:
        print("custom_nodes.yml file not found")

def download_models():
    """Download models based on custom_nodes.yml file"""
    if os.path.exists("docker/configs/custom_nodes.yml"):
        run_command("python scripts/download_models.py")
    else:
        print("custom_nodes.yml file not found")

if __name__ == "__main__":
    install_conda()
    create_conda_env()
    clone_comfyui()
    install_nodes()
    download_models()
    print("Script execution completed")