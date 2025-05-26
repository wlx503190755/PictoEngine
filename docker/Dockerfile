# 基础 python 镜像
FROM ubuntu:22.04

# 工作目录
WORKDIR /ComfyUI

# 安装系统依赖
RUN apt-get update && apt-get install gcc  python3-venv build-essential git  libgl1 libgl1-mesa-glx ffmpeg libglib2.0-0 libsm6 libxrender1 libxext6 wget -y

#设置容器启动后代理地址
#ENV https_proxy http://xxxx
#ENV no_proxy mirrors.xxxx.com
#设置kimi环境变量
#ENV api_key=sk-xxxxxx
#ENV api_version=
#ENV api_base=https://api.moonshot.cn/v1
#ENV api_proxy=
#ENV api_model=moonshot-v1-8k

# 克隆特定版本的 ComfyUI
RUN git clone --branch v0.3.34  https://github.com/comfyanonymous/ComfyUI.git .
RUN python3 -m venv venv 
ENV PATH="/ComfyUI/venv/bin/:${PATH}"


# 安装 ComfyUI 依赖
RUN /ComfyUI/venv/bin/pip install -r requirements.txt

# 复制脚本、配置
COPY scripts/ /app/scripts/
COPY ../configs/ /app/configs/
RUN chmod +x /app/scripts/entrypoint.sh

# 安装自定义节点及依赖包,因目录映射问题放在后面执行
RUN /ComfyUI/venv/bin/python /app/scripts/install_nodes.py

# 暴露端口
EXPOSE 8188

# 设置运行脚本
ENTRYPOINT ["/app/scripts/entrypoint.sh"]