import os
import yaml
import subprocess
import shutil
from urllib.parse import urlparse
import socket



lang = os.getenv("lang", "en") 
base_dir = os.getenv("CLONE_DIR", "/data")

messages = {
    "zh": {
        "checking_git_lfs": "检查是否安装了 git-lfs",
        "huggingface_accessible": "检查 huggingface.co 是否可访问",
        "cloning_huggingface_repo": "正在克隆 Hugging Face 仓库: {}",
        "using_mirror_site": "使用镜像站点: {}",
        "repository_downloaded": "仓库下载完成: {}",
        "downloading_file": "正在下载文件: {}",
        "file_downloaded": "文件下载完成: {}",
        "error_downloading": "下载文件时出错: {}",
        "error_config_not_exist": "错误：配置文件不存在: {}",
        "error_reading_config": "读取配置文件时出错: {}",
        "error_empty_config": "错误：配置文件为空",
        "processing_section": "处理配置部分: {}",
        "processing_node": "处理节点: {}",
        "skipping_model": "跳过模型: {}，因为 url 或 path 为空",
        "downloading_completed": "下载完成！",
        "error_downloading_node": "下载时出错: {}"
    },
    "en": {
        "checking_git_lfs": "Checking if git-lfs is installed",
        "huggingface_accessible": "Checking if huggingface.co is accessible",
        "cloning_huggingface_repo": "Cloning Hugging Face repository: {}",
        "using_mirror_site": "Using mirror site: {}",
        "repository_downloaded": "Repository downloaded: {}",
        "downloading_file": "Downloading file: {}",
        "file_downloaded": "File downloaded: {}",
        "error_downloading": "Error downloading file: {}",
        "error_config_not_exist": "Error: Configuration file does not exist: {}",
        "error_reading_config": "Error reading configuration file: {}",
        "error_empty_config": "Error: Configuration file is empty",
        "processing_section": "Processing section: {}",
        "processing_node": "Processing node: {}",
        "skipping_model": "Skipping model: {} because url or path is empty",
        "downloading_completed": "Download completed!",
        "error_downloading_node": "Error during download: {}"
    }
}

def check_git_lfs_installed():
    """Check if git-lfs is installed"""
    try:
        subprocess.run(['git', 'lfs', '--version'], capture_output=True, check=True)
        return True
    except:
        return False

def check_huggingface_accessible():
    """Check if huggingface.co is accessible"""
    try:
        socket.setdefaulttimeout(5)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(('huggingface.co', 443))
        return True
    except:
        return False

def convert_huggingface_url(url):
    """Convert huggingface.co URL to mirror site"""
    if 'huggingface.co' in url:
        return url.replace('huggingface.co', 'hf-mirror.com')
    return url

def download_huggingface_repo(url, save_path):
    """Download Hugging Face repository using git lfs"""
    print(messages[lang]["cloning_huggingface_repo"].format(url))
    
    if 'huggingface.co' in url:
        if not check_huggingface_accessible():
            url = convert_huggingface_url(url)
            print(messages[lang]["using_mirror_site"].format(url))
    
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    
    if os.path.exists(save_path):
        shutil.rmtree(save_path)
    
    try:
        subprocess.run(['git', 'clone', url, save_path], check=True)
        
        if check_git_lfs_installed():
            os.chdir(save_path)
            subprocess.run(['git', 'lfs', 'pull'], check=True)
            os.chdir('../..')
        else:
            print("Warning: git-lfs not detected, skipping large file downloads. Please install git-lfs to download large files.")
        
        print(messages[lang]["repository_downloaded"].format(save_path))
        return True
    except subprocess.CalledProcessError as e:
        print(messages[lang]["error_downloading"].format(str(e)))
        return False

def download_file(url, save_path):
    """Download a single file"""
    print(messages[lang]["downloading_file"].format(url))
    
    if 'huggingface.co' in url:
        if not check_huggingface_accessible():
            url = convert_huggingface_url(url)
            print(messages[lang]["using_mirror_site"].format(url))
    
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    
    max_retries = 3
    for attempt in range(max_retries):
        try:
            subprocess.run(['wget', '-c', '-t', '3', '-O', save_path, url], check=True)
            print(messages[lang]["file_downloaded"].format(save_path))
            return True
        except subprocess.CalledProcessError as e:
            if attempt < max_retries - 1:
                print(f"Download failed, retrying attempt {attempt + 2}...")
                continue
            print(messages[lang]["error_downloading"].format(str(e)))
            return False

def is_single_file(path):
    """Determine if the path is a single file by checking file extensions"""
    file_extensions = ('.pth', '.onnx', '.pt', '.bin', '.safetensors', '.ckpt', '.vae', '.json', '.yaml', '.yml')
    return path.lower().endswith(file_extensions)

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, '../docker/configs/custom_nodes.yml')
    
    if not os.path.exists(config_path):
        print(messages[lang]["error_config_not_exist"].format(config_path))
        return
        
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
    except Exception as e:
        print(messages[lang]["error_reading_config"].format(str(e)))
        return
    
    if not config:
        print(messages[lang]["error_empty_config"])
        return
    
    
    
    for section_name, section_data in config.items():
        if not isinstance(section_data, list):
            continue
            
        print(messages[lang]["processing_section"].format(section_name))
        
        for node in section_data:
            if 'models' not in node:
                continue
                
            print(messages[lang]["processing_node"].format(node.get('name', 'unknown')))
            
            for model_info in node['models']:
                if not isinstance(model_info, dict):
                    print("Error: Model configuration format is incorrect")
                    continue
                    
                if not model_info.get('url') or not model_info.get('path'):
                    print(messages[lang]["skipping_model"].format(model_info.get('name', 'unknown')))
                    continue
                    
                url = model_info['url']
                relative_path = model_info['path']
                
                save_path = os.path.join(base_dir, relative_path)
                
                print(f"Processing:")
                print(f"URL: {url}")
                print(f"Save path: {save_path}")
                
                try:
                    if is_single_file(relative_path):
                        download_file(url, save_path)
                    else:
                        download_huggingface_repo(url, save_path)
                    print(messages[lang]["downloading_completed"])
                except Exception as e:
                    print(messages[lang]["error_downloading_node"].format(str(e)))

if __name__ == "__main__":
    main() 
