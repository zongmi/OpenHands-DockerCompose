[简体中文](README.md) | [English](README.en.md)

# OpenHands Docker Compose Deployment

This is a complete Docker Compose deployment solution for OpenHands, based on the [All-Hands-AI/OpenHands](https://github.com/All-Hands-AI/OpenHands) project. It aims to provide an easy-to-manage, scalable, and powerful environment for both development and production.

## ✨ Features

- **One-Click Deployment**: Use `make` commands to simplify all operations.
- **Environment Separation**: Supports `dev` and `prod` environments.
- **Easy Configuration**: Centralized management of all configurations via the `.env` file.
- **Data Persistence**: Critical data is stored in Docker volumes to ensure data safety.
- **Advanced Management**: Provides advanced management commands like backup, restore, clean, and update.
- **Comprehensive Monitoring**: Built-in status checks, log viewing, and resource monitoring.
- **Optional Nginx Proxy**: Includes Nginx configuration for easy reverse proxy and SSL setup.

## 🚀 Quick Start

### 1. Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/) (V2 version)

### 2. Initialize the Project

When using for the first time, run the following command to create necessary directories and configuration files:

```bash
make init
```

This command will:
- Create directories like `data`, `logs`, `workspace`, etc.
- Copy `.env.example` to `.env` if it doesn't exist.
- **Important**: Please edit the `.env` file according to your needs, especially the `LLM_API_KEY`.

### 3. Start the Services

```bash
make start
```

This command will pull the latest Docker images and start all core services. Once started, you can access the OpenHands UI at `http://localhost:3000`.

## 🔧 Usage Instructions

We provide three ways to manage your deployment: `Makefile` (recommended), `shell` scripts, and `docker-compose` (advanced).

| Task | Makefile Command (Recommended) | Shell / Docker Compose Command (Advanced) | Description |
| :--- | :--- | :--- | :--- |
| **Initialize** | `make init` | `mkdir -p ... && cp ...` | Creates necessary directories and config files for the first use. |
| **Pull Images** | `make pull` | `docker compose pull` | Pulls the latest Docker images for all services. |
| **Start Services** | `make start` | `./scripts/start.sh` | Starts all core services. |
| **Start Dev Env** | `make dev` | `./scripts/start.sh --env dev` | Starts the development environment using `docker-compose.dev.yml`. |
| **Start Prod Env** | `make prod` | `./scripts/start.sh --env prod` | Starts the production environment using `docker-compose.prod.yml`. |
| **Stop Services** | `make stop` | `./scripts/stop.sh` | Stops all running services. |
| **Restart Services** | `make restart` | `docker compose restart` | Restarts all services. |
| **View Logs** | `make logs` | `./scripts/logs.sh` | Displays logs for the services. |
| **Follow Logs** | `make logs-f` | `./scripts/logs.sh --follow` | Follows log output in real-time. |
| **Check Status** | `make status` | `docker compose ps` | Checks the running status of containers. |
| **Enter Container** | `make shell` | `docker compose exec openhands bash` | Enters the shell of the `openhands` service container. |
| **Clean Resources** | `make clean` | `./scripts/stop.sh --volumes --cleanup` | **Warning**: Stops services and removes all volumes and networks. |
| **Update Version** | `make update` | `docker compose pull && docker compose up -d` | Updates to the latest images and restarts services. |
| **Health Check** | `make health` | `curl -f http://localhost:3000/api/health` | Checks the health status of the OpenHands API. |
| **Monitor Resources** | `make monitor` | `docker stats --no-stream ...` | Displays real-time resource usage of containers. |

## ⚙️ Configuration

All configurations are managed through the `.env` file in the root directory. Here are some key configuration items:

| Variable | Description | Default Value |
| :--- | :--- | :--- |
| `LLM_API_KEY` | **Required**. Your language model API key. | `your-api-key-here` |
| `LLM_MODEL` | The language model you want to use. | `gpt-4-0125-preview` |
| `LLM_BASE_URL` | An alternative API URL for the language model. | (empty) |
| `HOST_PORT` | The port on which the OpenHands service is exposed on the host. | `3000` |
| `SANDBOX_USER_ID` | The user ID for running commands in the sandbox container. | `1000` |
| `WORKSPACE_BASE` | The working directory for the agent. | `./workspace` |
| `MAX_ITERATIONS` | The maximum number of iterations per task. | `100` |

## 📂 Directory Structure

```
.
├── .env                  # Your local configuration (created by make init)
├── .env.example          # Example configuration file
├── config.toml           # Core OpenHands configuration file
├── docker-compose.yml    # Base Docker Compose configuration
├── docker-compose.dev.yml # Development environment override
├── docker-compose.prod.yml# Production environment override
├── Makefile              # Collection of management commands
├── README.md             # This documentation (in Chinese)
├── README.en.md          # This documentation (in English)
├── data/                 # Persistent data (Docker volume)
├── logs/                 # Application logs
├── nginx/                # Nginx configuration files
│   └── nginx.conf
├── scripts/              # Management scripts
│   ├── start.sh
│   ├── stop.sh
│   └── logs.sh
├── trajectories/         # Stores trajectory logs for agent tasks
└── workspace/            # The agent's workspace
```

## 📂 Mounting External Projects

By default, OpenHands executes tasks in the `/workspace` directory inside the container. You can mount your local project directories to this path so that OpenHands can work directly on your code.

### Mounting a Single Project

The recommended method is to create a `docker-compose.override.yml` file. This file allows you to override or add configurations without modifying the main `docker-compose.yml`.

1.  Create a `docker-compose.override.yml` file in the project root.
2.  Add the following content to mount your local project path (e.g., `~/my-project`) to the container's `/workspace`:

    ```yaml
    # docker-compose.override.yml
    version: '3.8'
    services:
      openhands:
        volumes:
          - ~/my-project:/workspace
    ```

    **Note**: Please replace `~/my-project` with the actual path to your local project.

3.  Now, when you run `make start` or `make dev`, Docker Compose will automatically merge this override file, and OpenHands will operate in your project directory.

### Mounting Multiple Projects

If you need to work on multiple projects simultaneously, you can mount them to subdirectories within `/workspace`.

1.  Modify the `docker-compose.override.yml` file as follows:

    ```yaml
    # docker-compose.override.yml
    version: '3.8'
    services:
      openhands:
        volumes:
          - ~/my-project-a:/workspace/project-a
          - ~/my-project-b:/workspace/project-b
    ```

2.  In your `.env` file, specify the default working directory for OpenHands by setting the `WORKSPACE_BASE` environment variable:

    ```env
    # .env
    WORKSPACE_BASE=/workspace/project-a
    ```

    This way, OpenHands will default to executing tasks in `project-a`. You can dynamically switch to other directories (like `/workspace/project-b`) in the OpenHands UI or via the API.

### Environment-Specific Workspaces

Please note that the development and production environments use different default workspaces:
- **Production/Default Env (`make start` / `make prod`)**: Mounts to `./workspace`.
- **Development Env (`make dev`)**: Mounts to `./dev-workspace` (defined in `docker-compose.dev.yml`).

If you use an override file, it will affect all environments.

## 💡 Advanced Usage

### Backing Up Data

Run the following command to back up the `openhands-data` volume:

```bash
make backup
```

The backup file will be stored in the `backups/` directory, named with a timestamp.

### Restoring Data

To restore data from a backup, use the `restore` command and specify the `BACKUP` filename:

```bash
make restore BACKUP=openhands-backup-YYYYMMDD-HHMMSS.tar.gz
```

### Using the Nginx Reverse Proxy

If you want to use Nginx as a reverse proxy (e.g., for SSL termination), you can start the services with the `nginx` profile:

```bash
docker compose --profile nginx up -d
```

Ensure you have placed your SSL certificate and key in the `nginx/ssl/` directory and updated `nginx/nginx.conf` accordingly.

## ❓ Troubleshooting

### Services Fail to Start

1.  **Check Docker**: Ensure the Docker daemon is running (`docker info`).
2.  **Check for Port Conflicts**: Make sure port `3000` (or the `HOST_PORT` you configured in `.env`) is not in use.
3.  **View Logs**: Use `make logs` or `docker compose logs` to see detailed error messages.

### Permission Issues

If you encounter permission issues with the `workspace` directory on Linux, ensure that the `SANDBOX_USER_ID` matches your host user ID. You can find your user ID with the `id -u` command.
