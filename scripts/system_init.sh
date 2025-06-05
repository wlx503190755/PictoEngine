#!/bin/bash

set -e


lang=${lang:-en} 


if [ "$lang" == "en" ]; then
    ROOT_USER_ERROR="Please run this script as root user!" >&2
    UNSUPPORTED_OS="Unsupported system! Only RHEL/CentOS or Ubuntu/Debian are supported." >&2
    SYSTEM_FILE_LIMITS="Optimizing system file limits..."
    DOCKER_INSTALL="Installing Docker..."
    DOCKER_START_ERROR="Docker service failed to start, checking for errors..."
    NVIDIA_INSTALL="Installing NVIDIA related components..."
    DRIVER_VERSION_ERROR="Error: Unable to get driver version information, please check if the driver is installed correctly" >&2
    DOCKER_COMPOSE_INSTALL="Installing Docker Compose..."
    DOCKER_COMPOSE_SKIP="Docker Compose is already installed, skipping..."
    INIT_COMPLETE="Initialization complete!"
    NVIDIA_TEST_COMMAND="Please run the following command to verify if NVIDIA Docker is working properly:"
    NVIDIA_TEST_COMMAND_EXAMPLE="  docker run --rm --gpus all nvidia/cuda:12.9.0-base-ubuntu22.04 nvidia-smi"
else
    ROOT_USER_ERROR="请使用 root 用户运行此脚本！" >&2
    UNSUPPORTED_OS="不支持的系统！仅支持 RHEL/CentOS 或 Ubuntu/Debian。" >&2
    SYSTEM_FILE_LIMITS="优化系统文件打开数..."
    DOCKER_INSTALL="安装 Docker..."
    DOCKER_START_ERROR="Docker 服务启动失败，正在检查错误..."
    NVIDIA_INSTALL="安装 NVIDIA 相关组件..."
    DRIVER_VERSION_ERROR="错误: 无法获取驱动版本信息,请检查驱动是否正确安装" >&2
    DOCKER_COMPOSE_INSTALL="安装 Docker Compose..."
    DOCKER_COMPOSE_SKIP="Docker Compose 已安装，跳过..."
    INIT_COMPLETE="初始化完成！"
    NVIDIA_TEST_COMMAND="请运行以下命令验证 NVIDIA Docker 是否正常工作："
    NVIDIA_TEST_COMMAND_EXAMPLE="  docker run --rm --gpus all nvidia/cuda:12.9.0-base-ubuntu22.04 nvidia-smi"
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "$ROOT_USER_ERROR"
    exit 1
fi

if [ -f /etc/redhat-release ]; then
    OS_TYPE="rhel"
elif [ -f /etc/debian_version ]; then
    OS_TYPE="debian"
else
    echo "$UNSUPPORTED_OS"
    exit 1
fi

echo "$SYSTEM_FILE_LIMITS"
cat > /etc/security/limits.conf <<EOF
* soft nofile 65535
* hard nofile 65535
EOF

ulimit -n 65535

echo "$DOCKER_INSTALL"

if ! systemctl is-active --quiet docker || ! command -v docker &> /dev/null; then
    if [ "$OS_TYPE" = "rhel" ]; then
        # RHEL/CentOS
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io git git-lfs
    else
        # Ubuntu/Debian
        DEBIAN_FRONTEND=noninteractive apt-get remove -y docker docker-engine docker.io containerd runc || true
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            ca-certificates \
            curl \
            git \
            git-lfs \
            gnupg \
            lsb-release

        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null

        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    echo "Starting Docker service..."
    systemctl daemon-reload
    systemctl enable docker
    if ! systemctl start docker; then
        echo "$DOCKER_START_ERROR"
        systemctl status docker
        journalctl -xeu docker.service
        echo "Please check the above error messages and resolve the issues before retrying."
        exit 1
    fi
else
    echo "Docker is already installed and running, skipping installation..."
fi

echo "$NVIDIA_INSTALL"

DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null)
if [ -z "$DRIVER_VERSION" ]; then
    echo "$DRIVER_VERSION_ERROR"
fi




if [ "$OS_TYPE" = "rhel" ]; then
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | tee /etc/yum.repos.d/nvidia-docker.repo
    yum install -y nvidia-container-toolkit
else
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

    if [ "$OS_TYPE" = "debian" ]; then
        if [ "$distribution" = "ubuntu24.04" ]; then
            distribution="ubuntu22.04"
        fi
        if [ "$distribution" = "ubuntu20.04" ] || [ "$distribution" = "debian11" ]; then
            curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
            curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
            apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y nvidia-docker2
        else
            curl -sL https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
            curl -sL https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
            apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y nvidia-container-toolkit
        fi
    fi
fi

systemctl restart docker

echo "$DOCKER_COMPOSE_INSTALL"
if ! command -v docker-compose &> /dev/null; then
    LATEST_COMPOSE=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    if [ -z "$LATEST_COMPOSE" ]; then
        echo "Failed to fetch the latest version. Please check your network connection or the GitHub API."
    else
        echo "Latest version: $LATEST_COMPOSE"
        curl -L "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
else
    echo "$DOCKER_COMPOSE_SKIP"
fi
apt install python3-yaml
echo "$INIT_COMPLETE"
echo "$NVIDIA_TEST_COMMAND"
echo "$NVIDIA_TEST_COMMAND_EXAMPLE"
