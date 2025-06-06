#!/usr/bin/env python3

import os
import yaml
import subprocess
from pathlib import Path
from typing import Dict, List, Optional

# Color definitions
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'  # No Color

# Define directory paths
COMFYUI_DIR = Path(os.getenv("CLONE_DIR", "/ComfyUI"))
VENV_DIR = Path(os.getenv("VENV_DIR", "/ComfyUI/venv/bin"))
CONFIG_DIR = Path(os.getenv("CONFIG_DIR", "/app/configs"))
CONFIG_FILE = CONFIG_DIR / "custom_nodes.yml"

def run_command(cmd: List[str], cwd: Optional[str] = None) -> None:
    """Run command and print output"""
    subprocess.run(cmd, cwd=cwd, check=True)

def install_node(node: Dict) -> None:
    """Install a single node"""
    name = node["name"]
    node_type = node["type"]
    repo_url = node["repository"]
    version = node.get("version", "")
    install_path = node["install_path"]
    
    print(f"\n{Colors.YELLOW}Processing node: {name} (Type: {node_type}){Colors.NC}")
    
    if node_type != "Community":
        print("Skipping non-Community type node")
        return
    
    full_path = COMFYUI_DIR / install_path
    
    # Check installation path
    if full_path.exists():
        print("Node directory already exists, updating...")
        os.chdir(full_path)
        run_command(["git", "fetch", "origin"])
        
        if version:
            current_hash = subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
            if current_hash != version:
                print(f"Switching to specified commit: {version}")
                run_command(["git", "checkout", version])
            else:
                print("Already on the specified commit")
        else:
            print("No version specified, using the latest version")
            run_command(["git", "pull", "origin", "main"])
    else:
        print("Cloning node repository...")
        run_command(["git", "clone", repo_url, str(full_path)])
        if version:
            os.chdir(full_path)
            print(f"Switching to specified commit: {version}")
            run_command(["git", "checkout", version])
    
    # Install dependencies
    requirements_file = full_path / "requirements.txt"
    if requirements_file.exists():
        print("Installing dependencies...")
        run_command([str(VENV_DIR / "pip"), "install", "-r", str(requirements_file)])
    
    # Check for additional installation scripts
    install_script = full_path / "install.py"
    if install_script.exists():
        print("Running installation script...")
        run_command([str(VENV_DIR / "python"), str(install_script)])

def main():
    # Check configuration file
    if not CONFIG_FILE.exists():
        print(f"{Colors.RED}Error: Configuration file {CONFIG_FILE} not found{Colors.NC}")
        exit(1)
    
    # Read configuration file
    with open(CONFIG_FILE, 'r') as f:
        config = yaml.safe_load(f)
    
    nodes = config.get('custom_nodes', [])
    print(f"{Colors.YELLOW}Starting installation of custom nodes...{Colors.NC}")
    print(f"Found {len(nodes)} node configurations")
    
    # Install all nodes
    for node in nodes:
        install_node(node)
    
    print(f"\n{Colors.GREEN}All nodes installed successfully{Colors.NC}")
    
    # Check for unconfigured nodes
    print(f"\n{Colors.YELLOW}Checking for additional nodes...{Colors.NC}")
    configured_nodes = {node['name'] for node in nodes}
    
    for node_dir in (COMFYUI_DIR / "custom_nodes").glob("*/"):
        node_name = node_dir.name
        if node_name not in configured_nodes:
            print(f"Found additional node: {node_name}, installing dependencies")
            requirements_file = node_dir / "requirements.txt"
            if requirements_file.exists():
                run_command([str(VENV_DIR / "pip"), "install", "-r", str(requirements_file)])
    
    print(f"\n{Colors.GREEN}Node installation and dependency check completed{Colors.NC}")

if __name__ == "__main__":
    main() 