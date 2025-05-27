#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="/data"
BACKUP_DIR="$DATA_DIR/backups"

# 初始化系统
init_system() {
    echo -e "${YELLOW}开始初始化系统...${NC}"
    bash "$SCRIPT_DIR/system_init.sh"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}系统初始化完成${NC}"
    else
        echo -e "${RED}系统初始化失败${NC}"
        exit 1
    fi
}
    
# 从 docker-compose.yml 获取镜像名称和版本
get_image_name() {
    IMAGE_NAME=$(grep 'image:' "$PROJECT_ROOT/docker/docker-compose.yml" | awk '{print $2}')
    IMAGE_NAME=$(echo "$IMAGE_NAME" | tr -d '\r')
    echo "$IMAGE_NAME"
}

# 从容器复制必要文件
copy_container_files() {
    echo -e "${YELLOW}从容器复制必要文件...${NC}"
    cd "$PROJECT_ROOT/docker"

    # 获取镜像名称
    IMAGE_NAME=$(get_image_name)

    # 创建临时容器
    docker create --name temp_container "$IMAGE_NAME"
    # 确保目标目录存在
    mkdir -p "$DATA_DIR"
    
    # 复制文件
    docker cp temp_container:/ComfyUI/venv "$DATA_DIR/"
    docker cp temp_container:/ComfyUI/custom_nodes "$DATA_DIR/"
    docker cp temp_container:/ComfyUI/models "$DATA_DIR/"
    
    # 清理临时容器
    docker rm temp_container
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}文件复制完成${NC}"
    else
        echo -e "${RED}文件复制失败${NC}"
        exit 1
    fi
    cd "$PROJECT_ROOT"
}

# 下载模型
download_models() {
    echo -e "${YELLOW}开始下载模型...${NC}"
    $DATA_DIR/venv/bin/python "$SCRIPT_DIR/download_models.py"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}模型下载完成${NC}"
    else
        echo -e "${RED}模型下载失败${NC}"
        exit 1
    fi
}
# 构建
build() {
    echo -e "${YELLOW}启动服务...${NC}"
    cd "$PROJECT_ROOT/docker"
    docker-compose build --no-cache
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}构建成功${NC}"
    else
        echo -e "${RED}构建失败${NC}"
        exit 1
    fi
}


# 首次初始化
init() {
    init_system
    read -p "请选择操作: 输入 'local' 进行本地构建，输入 'docker' 下载镜像: " choice
    if [ "$choice" == "local" ]; then
        echo -e "${YELLOW}开始本地构建...${NC}"
        build  # 调用构建函数
    elif [ "$choice" == "docker" ]; then
        echo -e "${YELLOW}根据 docker-compose.yml 下载镜像...${NC}"
        # 这里可以添加下载镜像的逻辑，例如：
        cd "$PROJECT_ROOT/docker"
        docker-compose pull
    else
        echo -e "${RED}无效选择，请输入 'local' 或 'docker'。${NC}"
        exit 1
    fi

    copy_container_files
    download_models
}


# 更新项目
update() {
    echo -e "${YELLOW}开始更新项目...${NC}"
    
    # 备份当前状态
    backup
    
    # 更新git仓库
    cd "$PROJECT_ROOT"
    git pull
    
    # 更新容器文件
    copy_container_files
    
    # 下载模型
    download_models
    
    echo -e "${GREEN}项目更新完成${NC}"
}

# 启动服务
start() {
    echo -e "${YELLOW}启动服务...${NC}"
    cd "$PROJECT_ROOT/docker"
    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}服务启动成功${NC}"
    else
        echo -e "${RED}服务启动失败${NC}"
        exit 1
    fi
}

# 停止服务
stop() {
    echo -e "${YELLOW}停止服务...${NC}"
    cd "$PROJECT_ROOT/docker"
    docker-compose down
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}服务停止成功${NC}"
    else
        echo -e "${RED}服务停止失败${NC}"
        exit 1
    fi
}

# 重启服务
restart() {
    stop
    start
}

# 检查服务状态
check_status() {
    cd "$PROJECT_ROOT/docker"
    docker-compose ps
}

# 查看日志
view_logs() {
    cd "$PROJECT_ROOT/docker"
    docker-compose logs -f
}

# 备份
backup() {
    echo -e "${YELLOW}开始备份...${NC}"
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
    CURRENT_BACKUP="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$CURRENT_BACKUP"
    
    # 备份数据目录
    cp -r "$DATA_DIR/venv" "$CURRENT_BACKUP/"
    cp -r "$DATA_DIR/models" "$CURRENT_BACKUP/"
    cp -r "$DATA_DIR/custom_nodes" "$CURRENT_BACKUP/"
    
    # 备份docker-compose.yml
    cp "$PROJECT_ROOT/docker/docker-compose.yml" "$CURRENT_BACKUP/"
    
    # 只保留最新的两份备份
    ls -t "$BACKUP_DIR"/backup_* | tail -n +3 | xargs -r rm -rf
    
    echo -e "${GREEN}备份完成: $CURRENT_BACKUP${NC}"
}

# 恢复备份
restore() {
    echo -e "${YELLOW}开始恢复备份...${NC}"
    
    # 获取最新的备份
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/backup_* | head -n 1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        echo -e "${RED}未找到备份${NC}"
        exit 1
    fi
    
    # 恢复数据目录
    cp -r "$LATEST_BACKUP/venv" "$DATA_DIR/"
    cp -r "$LATEST_BACKUP/models" "$DATA_DIR/"
    cp -r "$LATEST_BACKUP/custom_nodes" "$DATA_DIR/"
    
    # 恢复docker-compose.yml
    cp "$LATEST_BACKUP/docker-compose.yml" "$PROJECT_ROOT/docker/"
    
    echo -e "${GREEN}恢复完成${NC}"
}

# 主函数
main() {
    case "$1" in
        "init")
            init
            ;;
        "build")
            build
            ;;
        "dlmodels")
            download_models
            ;;
        "update")
            update
            ;;
        "start")
            start
            ;;
        "stop")
            stop
            ;;
        "restart")
            restart
            ;;
        "status")
            check_status
            ;;
        "logs")
            view_logs
            ;;
        "backup")
            backup
            ;;
        "restore")
            restore
            ;;
        *)
            echo "用法: $0 {init|build|dlmodels|update|start|stop|restart|status|logs|backup|restore}"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@" 
