import os
import yaml
import subprocess
import shutil
from urllib.parse import urlparse
import socket

def check_git_lfs_installed():
    """检查是否安装了 git-lfs"""
    try:
        subprocess.run(['git', 'lfs', '--version'], capture_output=True, check=True)
        return True
    except:
        return False

def check_huggingface_accessible():
    """检查 huggingface.co 是否可访问"""
    try:
        # 设置超时时间为5秒
        socket.setdefaulttimeout(5)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(('huggingface.co', 443))
        return True
    except:
        return False

def convert_huggingface_url(url):
    """转换 huggingface.co URL 到镜像站点"""
    if 'huggingface.co' in url:
        return url.replace('huggingface.co', 'hf-mirror.com')
    return url

def download_huggingface_repo(url, save_path):
    """使用 git lfs 下载 Hugging Face 仓库"""
    print(f"正在克隆 Hugging Face 仓库: {url}")
    
    # 检查并转换 huggingface URL
    if 'huggingface.co' in url:
        if not check_huggingface_accessible():
            url = convert_huggingface_url(url)
            print(f"使用镜像站点: {url}")
    
    # 确保目标目录的父目录存在
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    
    # 如果目标目录已存在，先删除
    if os.path.exists(save_path):
        shutil.rmtree(save_path)
    
    try:
        # 使用转换后的 URL 克隆仓库
        subprocess.run(['git', 'clone', url, save_path], check=True)
        
        # 如果安装了 git-lfs，则拉取 LFS 文件
        if check_git_lfs_installed():
            os.chdir(save_path)
            subprocess.run(['git', 'lfs', 'pull'], check=True)
            os.chdir('../..')  # 返回原目录
        else:
            print("注意：未检测到 git-lfs，跳过大文件下载。如需下载大文件，请先安装 git-lfs")
        
        print(f"仓库下载完成: {save_path}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"下载仓库时出错: {str(e)}")
        return False

def download_file(url, save_path):
    """下载单个文件"""
    print(f"正在下载文件: {url}")
    
    # 检查并转换 huggingface URL
    if 'huggingface.co' in url:
        if not check_huggingface_accessible():
            url = convert_huggingface_url(url)
            print(f"使用镜像站点: {url}")
    
    # 确保目标目录存在
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    
    # 添加重试机制
    max_retries = 3
    for attempt in range(max_retries):
        try:
            # 添加 -c 参数支持断点续传，-t 参数设置重试次数
            subprocess.run(['wget', '-c', '-t', '3', '-O', save_path, url], check=True)
            print(f"文件下载完成: {save_path}")
            return True
        except subprocess.CalledProcessError as e:
            if attempt < max_retries - 1:
                print(f"下载失败，正在进行第 {attempt + 2} 次尝试...")
                continue
            print(f"下载文件时出错: {str(e)}")
            return False

def is_single_file(path):
    """通过检查路径是否以文件扩展名结尾来判断是否为单个文件"""
    file_extensions = ('.pth', '.onnx', '.pt', '.bin', '.safetensors', '.ckpt', '.vae', '.json', '.yaml', '.yml')
    return path.lower().endswith(file_extensions)

def main():
    # 获取脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 读取YAML配置文件
    config_path = os.path.join(script_dir, '../docker/configs/custom_nodes.yml')
    
    if not os.path.exists(config_path):
        print(f"错误：配置文件不存在: {config_path}")
        return
        
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
    except Exception as e:
        print(f"读取配置文件时出错: {str(e)}")
        return
    
    if not config:
        print("错误：配置文件为空")
        return
    
    # 基础目录
    base_dir = "$clone_dir"
    
    # 遍历所有配置部分
    for section_name, section_data in config.items():
        if not isinstance(section_data, list):
            continue
            
        print(f"\n处理配置部分: {section_name}")
        
        # 遍历该部分下的所有节点
        for node in section_data:
            if 'models' not in node:
                continue
                
            print(f"\n处理节点: {node.get('name', 'unknown')}")
            
            # 遍历该节点下的models
            for model_info in node['models']:
                if not isinstance(model_info, dict):
                    print(f"错误：模型配置格式不正确")
                    continue
                    
                if not model_info.get('url') or not model_info.get('path'):
                    print(f"跳过模型: {model_info.get('name', 'unknown')}，因为 url 或 path 为空")
                    continue
                    
                url = model_info['url']
                relative_path = model_info['path']
                
                # 构建完整的保存路径
                save_path = os.path.join(base_dir, relative_path)
                
                print(f"正在处理:")
                print(f"URL: {url}")
                print(f"保存路径: {save_path}")
                
                try:
                    if is_single_file(relative_path):
                        download_file(url, save_path)
                    else:
                        download_huggingface_repo(url, save_path)
                    print(f"下载完成！\n")
                except Exception as e:
                    print(f"下载时出错: {str(e)}\n")

if __name__ == "__main__":
    main() 
