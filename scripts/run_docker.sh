#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'


lang=${lang:-en} 


if [ "$lang" == "en" ]; then
    INIT_START="Starting system initialization..."
    INIT_SUCCESS="System initialization completed"
    INIT_FAILURE="System initialization failed"
    FILE_COPY_START="Copying necessary files from the container..."
    FILE_COPY_SUCCESS="File copy completed"
    FILE_COPY_FAILURE="File copy failed"
    MODEL_DOWNLOAD_START="Starting model download..."
    MODEL_DOWNLOAD_SUCCESS="Model download completed"
    MODEL_DOWNLOAD_FAILURE="Model download failed"
    BUILD_START="Starting build..."
    BUILD_SUCCESS="Build successful"
    BUILD_FAILURE="Build failed"
    INVALID_CHOICE="Invalid choice, default to download the image."
    PROJECT_UPDATE_START="Starting project update..."
    PROJECT_UPDATE_SUCCESS="Project update completed"
    LOCAL_BUILD_START="Starting local build..."
    DOCKER_IMAGE_DOWNLOAD_START="Downloading image according to docker-compose.yml..."
    SERVICE_START_START="Starting service..."
    SERVICE_START_SUCCESS="Service started successfully, please fill the following address to the PIC client: "
    SERVICE_START_FAILURE="Service start failed"
    SERVICE_STOP_START="Stopping service..."
    SERVICE_STOP_SUCCESS="Service stopped successfully"
    SERVICE_STOP_FAILURE="Service stop failed"
    BACKUP_START="Starting backup..."
    BACKUP_COMPLETED="Backup completed: "
    RESTORE_START="Starting restore from backup..."
    NO_BACKUP_FOUND="No backup found"
    RESTORE_COMPLETED="Restore completed"
    USAGE="Usage: $0 {init|build|dlmodels|update|start|stop|restart|status|logs|backup|restore}"
    OPERATION_PROMPT="Please choose an operation, default to download the image: 1) local build, 2) download the image: [1/2]"
else
    INIT_START="开始初始化系统..."
    INIT_SUCCESS="系统初始化完成"
    INIT_FAILURE="系统初始化失败"
    FILE_COPY_START="从容器复制必要文件..."
    FILE_COPY_SUCCESS="文件复制完成"
    FILE_COPY_FAILURE="文件复制失败"
    MODEL_DOWNLOAD_START="开始下载模型..."
    MODEL_DOWNLOAD_SUCCESS="模型下载完成"
    MODEL_DOWNLOAD_FAILURE="模型下载失败"
    BUILD_START="启动构建..."
    BUILD_SUCCESS="构建成功"
    BUILD_FAILURE="构建失败"
    INVALID_CHOICE="无效选择，默认下载镜像。"
    PROJECT_UPDATE_START="开始更新项目..."
    PROJECT_UPDATE_SUCCESS="项目更新完成"
    LOCAL_BUILD_START="开始本地构建..."
    DOCKER_IMAGE_DOWNLOAD_START="根据 docker-compose.yml 下载镜像..."
    SERVICE_START_START="启动服务..."
    SERVICE_START_SUCCESS="服务启动成功，请将如下地址填写至PIC客户端: "
    SERVICE_START_FAILURE="服务启动失败"
    SERVICE_STOP_START="停止服务..."
    SERVICE_STOP_SUCCESS="服务停止成功"
    SERVICE_STOP_FAILURE="服务停止失败"
    BACKUP_START="开始备份..."
    BACKUP_COMPLETED="备份完成: "
    RESTORE_START="开始恢复备份..."
    NO_BACKUP_FOUND="未找到备份"
    RESTORE_COMPLETED="恢复完成"
    USAGE="用法: $0 {init|build|dlmodels|update|start|stop|restart|status|logs|backup|restore}"
    OPERATION_PROMPT="请选择操作,默认下载远程镜像: 1) 本地构建镜像，2) 下载远程镜像: [1/2]"
fi


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$CLONE_DIR"
BACKUP_DIR="$DATA_DIR/backups"


init_system() {
    echo -e "${YELLOW}$INIT_START${NC}"
    bash "$SCRIPT_DIR/system_init.sh"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$INIT_SUCCESS${NC}"
    else
        echo -e "${RED}$INIT_FAILURE${NC}"
        exit 1
    fi
}


get_image_name() {
    IMAGE_NAME=$(grep 'image:' "$PROJECT_ROOT/docker/docker-compose.yml" | awk '{print $2}')
    IMAGE_NAME=$(echo "$IMAGE_NAME" | tr -d '\r')
    echo "$IMAGE_NAME"
}


copy_container_files() {
    echo -e "${YELLOW}$FILE_COPY_START${NC}"
    cd "$PROJECT_ROOT/docker"

    
    IMAGE_NAME=$(get_image_name)

    
    docker create --name temp_container "$IMAGE_NAME"
    
    mkdir -p "$DATA_DIR"
    
    
    docker cp temp_container:/ComfyUI/venv "$DATA_DIR/"
    docker cp temp_container:/ComfyUI/custom_nodes "$DATA_DIR/"
    docker cp temp_container:/ComfyUI/models "$DATA_DIR/"
    
    
    docker rm temp_container
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$FILE_COPY_SUCCESS${NC}"
    else
        echo -e "${RED}$FILE_COPY_FAILURE${NC}"
        exit 1
    fi
    cd "$PROJECT_ROOT"
}


download_models() {
    echo -e "${YELLOW}$MODEL_DOWNLOAD_START${NC}"
    python3 "$SCRIPT_DIR/download_models.py"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$MODEL_DOWNLOAD_SUCCESS${NC}"
    else
        echo -e "${RED}$MODEL_DOWNLOAD_FAILURE${NC}"
        exit 1
    fi
}


build() {
    echo -e "${YELLOW}$BUILD_START${NC}"
    cd "$PROJECT_ROOT/docker"
    docker-compose build --no-cache
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$BUILD_SUCCESS${NC}"
    else
        echo -e "${RED}$BUILD_FAILURE${NC}"
        exit 1
    fi
}


init() {
    init_system
    read -p "$OPERATION_PROMPT" choice
    if [ "$choice" == "1" ]; then
        echo -e "${YELLOW}$LOCAL_BUILD_START${NC}"
        build
    else
        echo -e "${YELLOW}$DOCKER_IMAGE_DOWNLOAD_START${NC}"
        cd "$PROJECT_ROOT/docker"
        docker-compose pull
    fi

    copy_container_files
    download_models
}


update() {
    echo -e "${YELLOW}$PROJECT_UPDATE_START${NC}"
    

    backup
    

    cd "$PROJECT_ROOT"
    git pull
    

    copy_container_files
    

    download_models
    
    echo -e "${GREEN}$PROJECT_UPDATE_SUCCESS${NC}"
}


start() {
    echo -e "${YELLOW}$SERVICE_START_START${NC}"
    cd "$PROJECT_ROOT/docker"
    docker-compose up -d
    if [ $? -eq 0 ]; then
        source /etc/profile
        server_url=`ip -br addr show | awk -v port="${server_port}" '$2 == "UP" && !/lo|docker|virbr|veth|br-|tun|tap/ {split($3, a, "/"); print "http://" a[1] ":" port}' || echo "http://127.0.0.1:${server_port}"`
        echo -e "${GREEN}$SERVICE_START_SUCCESS${NC} $server_url"
    else
        echo -e "${RED}$SERVICE_START_FAILURE${NC}"
        exit 1
    fi
}


stop() {
    echo -e "${YELLOW}$SERVICE_STOP_START${NC}"
    cd "$PROJECT_ROOT/docker"
    docker-compose down
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$SERVICE_STOP_SUCCESS${NC}"
    else
        echo -e "${RED}$SERVICE_STOP_FAILURE${NC}"
        exit 1
    fi
}


restart() {
    stop
    start
}


check_status() {
    cd "$PROJECT_ROOT/docker"
    docker-compose ps
}


view_logs() {
    cd "$PROJECT_ROOT/docker"
    docker-compose logs -f
}


backup() {
    echo -e "${YELLOW}$BACKUP_START${NC}"
    

    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
    CURRENT_BACKUP="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$CURRENT_BACKUP"
    

    cp -r "$DATA_DIR/venv" "$CURRENT_BACKUP/"
    cp -r "$DATA_DIR/models" "$CURRENT_BACKUP/"
    cp -r "$DATA_DIR/custom_nodes" "$CURRENT_BACKUP/"
    

    cp "$PROJECT_ROOT/docker/docker-compose.yml" "$CURRENT_BACKUP/"
    

    ls -t "$BACKUP_DIR"/backup_* | tail -n +3 | xargs -r rm -rf
    
    echo -e "${GREEN}$BACKUP_COMPLETED$CURRENT_BACKUP${NC}"
}


restore() {
    echo -e "${YELLOW}$RESTORE_START${NC}"
    

    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/backup_* | head -n 1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        echo -e "${RED}$NO_BACKUP_FOUND${NC}"
        exit 1
    fi
    

    cp -r "$LATEST_BACKUP/venv" "$DATA_DIR/"
    cp -r "$LATEST_BACKUP/models" "$DATA_DIR/"
    cp -r "$LATEST_BACKUP/custom_nodes" "$DATA_DIR/"
    

    cp "$LATEST_BACKUP/docker-compose.yml" "$PROJECT_ROOT/docker/"
    
    echo -e "${GREEN}$RESTORE_COMPLETED${NC}"
}


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
            echo "$USAGE"
            exit 1
            ;;
    esac
}


main "$@" 
