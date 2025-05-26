#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 定义目录路径
COMFYUI_DIR="/ComfyUI"
CONFIG_DIR="/app/configs"
CONFIG_FILE="$CONFIG_DIR/custom_nodes.yml"

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}错误: 未找到配置文件 $CONFIG_FILE${NC}"
    exit 1
fi

# 使用 Python 解析 YAML 并获取节点数量
NODE_COUNT=$($COMFYUI_DIR/venv/bin/python -c "
import yaml
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    print(len(config.get('custom_nodes', [])))
")

echo -e "${YELLOW}开始安装自定义节点...${NC}"
echo "找到 $NODE_COUNT 个节点配置"

# 遍历所有节点
for i in $(seq 0 $((NODE_COUNT-1))); do
    # 使用 Python 获取节点信息
    NODE_INFO=$($COMFYUI_DIR/venv/bin/python -c "
import yaml
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    node = config['custom_nodes'][$i]
    print(f'{node[\"name\"]}|{node[\"type\"]}|{node[\"repository\"]}|{node.get(\"version\", \"\")}|{node[\"install_path\"]}')
")
    
    # 解析节点信息
    NODE_NAME=$(echo "$NODE_INFO" | cut -d'|' -f1)
    NODE_TYPE=$(echo "$NODE_INFO" | cut -d'|' -f2)
    REPO_URL=$(echo "$NODE_INFO" | cut -d'|' -f3)
    VERSION=$(echo "$NODE_INFO" | cut -d'|' -f4)
    INSTALL_PATH=$(echo "$NODE_INFO" | cut -d'|' -f5)
    
    # 添加调试信息
    echo "节点信息:"
    echo "名称: $NODE_NAME"
    echo "类型: $NODE_TYPE"
    echo "仓库: $REPO_URL"
    echo "版本: $VERSION"
    echo "路径: $INSTALL_PATH"
    
    echo -e "\n${YELLOW}处理节点: $NODE_NAME (类型: $NODE_TYPE)${NC}"
    
    # 只处理 Community 类型的节点
    if [ "$NODE_TYPE" = "Community" ]; then
        # 检查安装路径
        if [ -d "$COMFYUI_DIR/$INSTALL_PATH" ]; then
            echo "节点目录已存在，更新中..."
            cd "$COMFYUI_DIR/$INSTALL_PATH"
            git fetch origin
            if [ ! -z "$VERSION" ]; then
                # 检查当前 commit hash
                CURRENT_HASH=$(git rev-parse HEAD)
                if [ "$CURRENT_HASH" != "$VERSION" ]; then
                    echo "切换到指定 commit: $VERSION"
                    git checkout "$VERSION"
                else
                    echo "已经在指定的 commit 上"
                fi
            else
                echo "未指定版本，使用最新版本"
                git pull origin main
            fi
        else
            echo "克隆节点仓库..."
            git clone "$REPO_URL" "$COMFYUI_DIR/$INSTALL_PATH"
            if [ ! -z "$VERSION" ]; then
                cd "$COMFYUI_DIR/$INSTALL_PATH"
                echo "切换到指定 commit: $VERSION"
                git checkout "$VERSION"
            fi
        fi
        
        # 安装依赖
        if [ -f "$COMFYUI_DIR/$INSTALL_PATH/requirements.txt" ]; then
            echo "安装依赖..."
            $COMFYUI_DIR/venv/bin/pip install -r "$COMFYUI_DIR/$INSTALL_PATH/requirements.txt"
        fi
        
        # 检查是否有额外的安装脚本
        if [ -f "$COMFYUI_DIR/$INSTALL_PATH/install.py" ]; then
            echo "运行安装脚本..."
            $COMFYUI_DIR/venv/bin/python "$COMFYUI_DIR/$INSTALL_PATH/install.py"
        fi
    else
        echo "跳过非 Community 类型节点"
    fi
done

echo -e "\n${GREEN}所有节点安装完成${NC}"

# 检查未配置的节点
echo -e "\n${YELLOW}检查额外节点...${NC}"
CONFIGURED_NODES=$($COMFYUI_DIR/venv/bin/python -c "
import yaml
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    print('\n'.join(node['name'] for node in config.get('custom_nodes', [])))
")

for node_dir in $COMFYUI_DIR/custom_nodes/*/; do
    node_name=$(basename "$node_dir")
    if ! echo "$CONFIGURED_NODES" | grep -q "^$node_name$"; then
        echo "发现额外节点: $node_name，安装依赖"
        if [ -f "$node_dir/requirements.txt" ]; then
            $COMFYUI_DIR/venv/bin/pip install -r "$node_dir/requirements.txt"
        fi
    fi
done

echo -e "\n${GREEN}节点安装和依赖检查完成${NC}" 