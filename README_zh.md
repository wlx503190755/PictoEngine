# Comfu Docker

## 项目简介
Comfu Docker 是一个基于 Docker 的容器化部署解决方案，用于简化应用程序的部署和管理流程。

## 目录结构 
```
PictoEngine/
├── docker/
├── scripts/
└── README.md
``` 

## 环境要求
- 显卡支持 cuda 12.1 或更高版本
- Docker 20.10.0 或更高版本
- Docker Compose 2.0.0 或更高版本
- Linux/Unix 环境（用于运行 shell/python 脚本）

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/pictorialink/PictoEngine.git
cd PictoEngine
```

### 2. 运行部署脚本
```bash
chmod +x ./scripts/run_docker.sh
./scripts/run_docker.sh
```

## 使用说明

### 主要命令
- 初始化：`./scripts/run_docker.sh init`
- 启动服务：`./scripts/run_docker.sh start`
- 停止服务：`./scripts/run_docker.sh stop`
- 重启服务：`./scripts/run_docker.sh restart`
- 查看状态：`./scripts/run_docker.sh status`
- 查看日志：`./scripts/run_docker.sh logs`

### 脚本功能说明
`run_docker.sh` 脚本提供以下功能：
- 初始化
- 环境检查
- 容器构建
- 服务启动
- 服务停止
- 状态查看
- 日志查看


## 常见问题
1. 如果遇到权限问题，请确保 `run_docker.sh` 具有执行权限
2. 确保 Docker 服务正在运行
3. 检查网络连接是否正常

## 贡献指南
欢迎提交 Issue 和 Pull Request 来帮助改进项目。

## 许可证
[MIT License](LICENSE)

## 联系方式
如有问题，请通过以下方式联系：
- 提交 Issue
- 发送邮件至：your.email@example.com 
