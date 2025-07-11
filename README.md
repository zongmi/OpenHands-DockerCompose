[简体中文](README.md) | [English](README.en.md)

# OpenHands Docker Compose 部署

这是一个完整的 OpenHands Docker Compose 部署方案，基于 [All-Hands-AI/OpenHands](https://github.com/All-Hands-AI/OpenHands) 项目，旨在提供一个易于管理、可扩展且功能强大的环境，适用于开发和生产。

## ✨ 特性

- **一键部署**: 使用 `make` 命令简化所有操作。
- **环境分离**: 支持开发 (`dev`) 和生产 (`prod`) 环境。
- **易于配置**: 通过 `.env` 文件集中管理所有配置。
- **数据持久化**: 关键数据存储在 Docker 卷中，确保数据安全。
- **高级管理**: 提供备份、恢复、清理和更新等高级管理命令。
- **全面监控**: 内置状态检查、日志查看和资源监控功能。
- **可选的 Nginx 代理**: 内置 Nginx 配置，可轻松实现反向代理和 SSL。

## 🚀 快速开始

### 1. 先决条件

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/) (V2 版本)

### 2. 初始化项目

首次使用时，运行以下命令创建必要的目录和配置文件：

```bash
make init
```

该命令会：
- 创建 `data`, `logs`, `workspace` 等目录。
- 从 `.env.example` 复制 `.env` 文件 (如果不存在)。
- **重要**: 请根据您的需求编辑 `.env` 文件，特别是 `LLM_API_KEY`。

### 3. 启动服务

```bash
make start
```

该命令会拉取最新的 Docker 镜像并启动所有核心服务。服务启动后，您可以通过 `http://localhost:3000` 访问 OpenHands UI。

## 🔧 使用说明

我们提供三种方式来管理您的部署：`Makefile` (推荐)、`shell` 脚本和 `docker-compose` (高级)。

| 任务 | Makefile 命令 (推荐) | Shell / Docker Compose 命令 (高级) | 描述 |
| :--- | :--- | :--- | :--- |
| **初始化** | `make init` | `mkdir -p ... && cp ...` | 首次使用时，创建必要的目录和配置文件。 |
| **拉取镜像** | `make pull` | `docker compose pull` | 拉取所有服务所需的最新 Docker 镜像。 |
| **启动服务** | `make start` | `./scripts/start.sh` | 启动所有核心服务。 |
| **开发环境启动** | `make dev` | `./scripts/start.sh --env dev` | 使用 `docker-compose.dev.yml` 启动开发环境。 |
| **生产环境启动** | `make prod` | `./scripts/start.sh --env prod` | 使用 `docker-compose.prod.yml` 启动生产环境。 |
| **停止服务** | `make stop` | `./scripts/stop.sh` | 停止所有正在运行的服务。 |
| **重启服务** | `make restart` | `docker compose restart` | 重启所有服务。 |
| **查看日志** | `make logs` | `./scripts/logs.sh` | 显示服务的日志。 |
| **实时日志** | `make logs-f` | `./scripts/logs.sh --follow` | 实时跟踪日志输出。 |
| **查看状态** | `make status` | `docker compose ps` | 检查容器的运行状态。 |
| **进入容器** | `make shell` | `docker compose exec openhands bash` | 进入 `openhands` 服务的容器 Shell。 |
| **清理资源** | `make clean` | `./scripts/stop.sh --volumes --cleanup` | **警告**: 停止服务并删除所有数据卷和网络。 |
| **更新版本** | `make update` | `docker compose pull && docker compose up -d` | 更新到最新版本的镜像并重启服务。 |
| **健康检查** | `make health` | `curl -f http://localhost:3000/api/health` | 检查 OpenHands API 的健康状态。 |
| **资源监控** | `make monitor` | `docker stats --no-stream ...` | 显示容器的实时资源使用情况。 |

## ⚙️ 配置

所有配置都通过根目录下的 `.env` 文件进行管理。以下是一些关键的配置项：

| 变量 | 描述 | 默认值 |
| :--- | :--- | :--- |
| `LLM_API_KEY` | **必需**。您的语言模型 API 密钥。 | `your-api-key-here` |
| `LLM_MODEL` | 您希望使用的语言模型。 | `gpt-4-0125-preview` |
| `LLM_BASE_URL` | 语言模型的备用 API 地址。 | (空) |
| `HOST_PORT` | OpenHands 服务暴露在主机上的端口。 | `3000` |
| `SANDBOX_USER_ID` | 沙箱容器中运行命令的用户 ID。 | `1000` |
| `WORKSPACE_BASE` | 代理的工作目录。 | `./workspace` |
| `MAX_ITERATIONS` | 每个任务的最大迭代次数。 | `100` |

## 📂 目录结构

```
.
├── .env                  # 您的本地配置 (由 make init 创建)
├── .env.example          # 配置示例文件
├── config.toml           # OpenHands 核心配置文件
├── docker-compose.yml    # 基础 Docker Compose 配置
├── docker-compose.dev.yml # 开发环境覆盖配置
├── docker-compose.prod.yml# 生产环境覆盖配置
├── Makefile              # 管理命令集合
├── README.md             # 本文档
├── data/                 # 持久化数据 (Docker 卷)
├── logs/                 # 应用日志
├── nginx/                # Nginx 配置文件
│   └── nginx.conf
├── scripts/              # 管理脚本
│   ├── start.sh
│   ├── stop.sh
│   └── logs.sh
├── trajectories/         # 存储代理执行任务的轨迹日志
└── workspace/            # 代理的工作空间
```

## 📂 挂载外部项目

默认情况下，OpenHands 在容器内的 `/workspace` 目录中执行任务。您可以将本地的项目目录挂载到此路径，以便 OpenHands 可以直接处理您的代码。

### 挂载单个项目

推荐的方法是创建一个 `docker-compose.override.yml` 文件。这个文件可以让你在不修改主 `docker-compose.yml` 的情况下，覆盖或添加配置。

1.  在项目根目录创建 `docker-compose.override.yml` 文件。
2.  添加以下内容，将您的本地项目路径 (例如 `~/my-project`) 挂载到容器的 `/workspace`：

    ```yaml
    # docker-compose.override.yml
    version: '3.8'
    services:
      openhands:
        volumes:
          - ~/my-project:/workspace
    ```

    **注意**: 请将 `~/my-project` 替换为您本地项目的实际路径。

3.  现在，当您运行 `make start` 或 `make dev` 时，Docker Compose 会自动合并这个覆盖文件，OpenHands 将在您的项目目录中工作。

### 挂载多个项目

如果您需要同时处理多个项目，可以将它们分别挂载到 `/workspace` 的子目录中。

1.  修改 `docker-compose.override.yml` 文件，如下所示：

    ```yaml
    # docker-compose.override.yml
    version: '3.8'
    services:
      openhands:
        volumes:
          - ~/my-project-a:/workspace/project-a
          - ~/my-project-b:/workspace/project-b
    ```

2.  在 `.env` 文件中，通过设置 `WORKSPACE_BASE` 环境变量来指定 OpenHands 的默认工作目录。例如：

    ```env
    # .env
    WORKSPACE_BASE=/workspace/project-a
    ```

    这样，OpenHands 将默认在 `project-a` 中执行任务。您可以在 OpenHands 的 UI 或通过 API 动态切换到其他目录 (如 `/workspace/project-b`)。

### 环境特定的工作区

请注意，开发环境和生产环境使用不同的默认工作区：
- **生产/默认环境 (`make start` / `make prod`)**: 挂载到 `./workspace`。
- **开发环境 (`make dev`)**: 挂载到 `./dev-workspace` (在 `docker-compose.dev.yml` 中定义)。

如果您使用覆盖文件，它将同时影响所有环境。

## 💡 高级用法

### 备份数据

运行以下命令来备份 `openhands-data` 卷：

```bash
make backup
```

备份文件将存储在 `backups/` 目录下，并以时间戳命名。

### 恢复数据

要从备份中恢复数据，请使用 `restore` 命令，并指定 `BACKUP` 文件名：

```bash
make restore BACKUP=openhands-backup-YYYYMMDD-HHMMSS.tar.gz
```

### 使用 Nginx 反向代理

如果您希望使用 Nginx 作为反向代理 (例如，用于 SSL 终止)，您可以使用 `nginx` 配置文件启动服务：

```bash
docker compose --profile nginx up -d
```

确保您已将 SSL 证书和密钥放在 `nginx/ssl/` 目录下，并相应地更新 `nginx/nginx.conf`。

## ❓ 故障排除

### 服务无法启动

1.  **检查 Docker**: 确保 Docker 守护进程正在运行 (`docker info`)。
2.  **检查端口冲突**: 确保端口 `3000` (或您在 `.env` 中配置的 `HOST_PORT`) 未被占用。
3.  **查看日志**: 使用 `make logs` 或 `docker compose logs` 查看详细的错误信息。

### 权限问题

如果在 Linux 上遇到 `workspace` 目录的权限问题，请确保 `SANDBOX_USER_ID` 与您的主机用户 ID 匹配。您可以使用 `id -u` 命令查看您的用户 ID。
