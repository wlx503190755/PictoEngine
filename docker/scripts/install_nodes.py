#!/usr/bin/env python3

import os
import yaml
import subprocess
from pathlib import Path
from typing import Dict, List, Optional

# 颜色定义
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'  # No Color

# 定义目录路径
COMFYUI_DIR = Path("/ComfyUI")
CONFIG_DIR = Path("/app/configs")
CONFIG_FILE = CONFIG_DIR / "custom_nodes.yml"

def run_command(cmd: List[str], cwd: Optional[str] = None) -> None:
    """运行命令并打印输出"""
    subprocess.run(cmd, cwd=cwd, check=True)

def install_node(node: Dict) -> None:
    """安装单个节点"""
    name = node["name"]
    node_type = node["type"]
    repo_url = node["repository"]
    version = node.get("version", "")
    install_path = node["install_path"]
    
    print(f"\n{Colors.YELLOW}处理节点: {name} (类型: {node_type}){Colors.NC}")
    
    if node_type != "Community":
        print("跳过非 Community 类型节点")
        return
    
    full_path = COMFYUI_DIR / install_path
    
    # 检查安装路径
    if full_path.exists():
        print("节点目录已存在，更新中...")
        os.chdir(full_path)
        run_command(["git", "fetch", "origin"])
        
        if version:
            current_hash = subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
            if current_hash != version:
                print(f"切换到指定 commit: {version}")
                run_command(["git", "checkout", version])
            else:
                print("已经在指定的 commit 上")
        else:
            print("未指定版本，使用最新版本")
            run_command(["git", "pull", "origin", "main"])
    else:
        print("克隆节点仓库...")
        run_command(["git", "clone", repo_url, str(full_path)])
        if version:
            os.chdir(full_path)
            print(f"切换到指定 commit: {version}")
            run_command(["git", "checkout", version])
    
    # 安装依赖
    requirements_file = full_path / "requirements.txt"
    if requirements_file.exists():
        print("安装依赖...")
        run_command([str(COMFYUI_DIR / "venv/bin/pip"), "install", "-r", str(requirements_file)])
    
    # 检查是否有额外的安装脚本
    install_script = full_path / "install.py"
    if install_script.exists():
        print("运行安装脚本...")
        run_command([str(COMFYUI_DIR / "venv/bin/python"), str(install_script)])

def main():
    # 检查配置文件
    if not CONFIG_FILE.exists():
        print(f"{Colors.RED}错误: 未找到配置文件 {CONFIG_FILE}{Colors.NC}")
        exit(1)
    
    # 读取配置文件
    with open(CONFIG_FILE, 'r') as f:
        config = yaml.safe_load(f)
    
    nodes = config.get('custom_nodes', [])
    print(f"{Colors.YELLOW}开始安装自定义节点...{Colors.NC}")
    print(f"找到 {len(nodes)} 个节点配置")
    
    # 安装所有节点
    for node in nodes:
        install_node(node)
    
    print(f"\n{Colors.GREEN}所有节点安装完成{Colors.NC}")
    
    # 检查未配置的节点
    print(f"\n{Colors.YELLOW}检查额外节点...{Colors.NC}")
    configured_nodes = {node['name'] for node in nodes}
    
    for node_dir in (COMFYUI_DIR / "custom_nodes").glob("*/"):
        node_name = node_dir.name
        if node_name not in configured_nodes:
            print(f"发现额外节点: {node_name}，安装依赖")
            requirements_file = node_dir / "requirements.txt"
            if requirements_file.exists():
                run_command([str(COMFYUI_DIR / "venv/bin/pip"), "install", "-r", str(requirements_file)])
    
    print(f"\n{Colors.GREEN}节点安装和依赖检查完成{Colors.NC}")

if __name__ == "__main__":
    main() 