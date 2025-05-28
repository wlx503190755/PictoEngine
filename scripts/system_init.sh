#!/bin/bash

set -e  # 遇到错误立即退出

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 用户运行此脚本！" >&2
    exit 1
fi

# 检测系统类型
if [ -f /etc/redhat-release ]; then
    OS_TYPE="rhel"
elif [ -f /etc/debian_version ]; then
    OS_TYPE="debian"
else
    echo "不支持的系统！仅支持 RHEL/CentOS 或 Ubuntu/Debian。" >&2
    exit 1
fi

# 1. 优化系统文件打开数
echo "优化系统文件打开数..."
cat > /etc/security/limits.conf <<EOF
* soft nofile 65535
* hard nofile 65535
EOF

# 临时生效（当前会话）
ulimit -n 65535

# 2. 安装 Docker（官方源）
echo "安装 Docker..."
# 改进 Docker 检测方法
if ! systemctl is-active --quiet docker || ! command -v docker &> /dev/null; then
    if [ "$OS_TYPE" = "rhel" ]; then
        # RHEL/CentOS
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
    else
        # Ubuntu/Debian
        # 移除旧版本（如果存在）
        apt-get remove -y docker docker-engine docker.io containerd runc
        
        # 安装必要的依赖
        apt-get update
        apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release

        # 添加 Docker 官方 GPG 密钥
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        # 添加 Docker 仓库
        echo \
          "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null

        # 安装 Docker
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    
    # 启动 Docker 服务
    echo "启动 Docker 服务..."
    systemctl daemon-reload
    systemctl enable docker
    if ! systemctl start docker; then
        echo "Docker 服务启动失败，正在检查错误..."
        systemctl status docker
        journalctl -xeu docker.service
        echo "请检查以上错误信息并解决问题后重试"
        exit 1
    fi
else
    echo "Docker 已安装且正在运行，跳过安装步骤..."
fi

# 3. 安装 NVIDIA 相关组件
echo "安装 NVIDIA 相关组件..."
# 检查 NVIDIA 驱动是否安装
DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null)
if [ -z "$DRIVER_VERSION" ]; then
        echo "错误: 无法获取驱动版本信息,请检查驱动是否正确安装" >&2
fi
# 对于 Ubuntu 24.04，使用 Ubuntu 22.04 的仓库
if [ "$distribution" = "ubuntu24.04" ]; then
        distribution="ubuntu22.04"
fi


if [ "$OS_TYPE" = "rhel" ]; then
    # RHEL/CentOS 安装 NVIDIA Container Toolkit
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | tee /etc/yum.repos.d/nvidia-docker.repo
    yum install -y nvidia-container-toolkit
else
    # Ubuntu/Debian 安装 nvidia-docker2 或 nvidia-container-toolkit
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

    # 对于 Ubuntu 24.04，使用 Ubuntu 22.04 的仓库
    if [ "$distribution" = "ubuntu24.04" ]; then
        distribution="ubuntu22.04"
    fi
        if [ "$distribution" = "ubuntu20.04" ] || [ "$distribution" = "debian11" ]; then
                curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
                curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
                apt-get update
                apt-get install -y nvidia-docker2
        else
                curl -sL https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
                curl -sL https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
                apt-get update
                apt-get install -y nvidia-container-toolkit
        fi

fi

# 重启 Docker
systemctl restart docker

# 4. 安装 Docker Compose（最新版）
echo "安装 Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
#    LATEST_COMPOSE=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    LATEST_COMPOSE=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    if [ -z "$LATEST_COMPOSE" ]; then
        echo "Failed to fetch the latest version. Please check your network connection or the GitHub API."
    else
        echo "Latest version: $LATEST_COMPOSE"
        curl -L "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi

else
    echo "Docker Compose 已安装，跳过..."
fi

echo "初始化完成！"
echo "请运行以下命令验证 NVIDIA Docker 是否正常工作："
echo "  docker run --rm --gpus all nvidia/cuda:12.9.0-base-ubuntu22.04 nvidia-smi"
