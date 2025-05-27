# Comfy Docker

## Project Overview
Comfy Docker is a containerized deployment solution based on Docker, designed to simplify the deployment and management process of applications.

## Directory Structure
```
PictoEngine/
├── docker/
├── scripts/
└── README.md
```

## Requirements
- GPU supporting CUDA 12.1 or higher
- Docker 20.10.0 or higher
- Docker Compose 2.0.0 or higher
- Linux/Unix environment (for running shell/python scripts)

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/pictorialink/PictoEngine.git
cd PictoEngine
```

### 2. Run Deployment Script
```bash
chmod +x ./scripts/run_docker.sh
./scripts/run_docker.sh
```

## Usage

### Main Commands
- Initialize: `./scripts/run_docker.sh init`
- Start service: `./scripts/run_docker.sh start`
- Stop service: `./scripts/run_docker.sh stop`
- Restart service: `./scripts/run_docker.sh restart`
- Check status: `./scripts/run_docker.sh status`
- View logs: `./scripts/run_docker.sh logs`

### Script Features
The `run_docker.sh` script provides the following features:
- Initialization
- Environment check
- Container building
- Service startup
- Service shutdown
- Status monitoring
- Log viewing

## Common Issues
1. If you encounter permission issues, ensure `run_docker.sh` has execution permissions
2. Make sure Docker service is running
3. Check if network connection is normal

## Contributing
Issues and Pull Requests are welcome to help improve the project.

## License
[MIT License](LICENSE)

## Contact
For any questions, please contact us through:
- Submit an Issue
- Send email to: your.email@example.com 
