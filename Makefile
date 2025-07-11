# OpenHands Docker Compose Makefile

.PHONY: help start stop restart logs status clean dev prod init pull backup restore

# 默认目标
.DEFAULT_GOAL := help

# 颜色定义
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
NC := \033[0m

# 帮助信息
help: ## 显示帮助信息
	@echo "$(BLUE)OpenHands Docker Compose 管理命令$(NC)"
	@echo ""
	@echo "$(GREEN)基础命令:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# 初始化
init: ## 初始化项目 (创建目录和配置文件)
	@echo "$(BLUE)初始化 OpenHands 项目...$(NC)"
	@mkdir -p data logs workspace trajectories nginx/ssl
	@if [ ! -f .env ]; then cp .env.example .env; echo "$(YELLOW)请编辑 .env 文件设置您的配置$(NC)"; fi
	@chmod +x scripts/*.sh
	@echo "$(GREEN)初始化完成$(NC)"

# 拉取镜像
pull: ## 拉取最新镜像
	@echo "$(BLUE)拉取 Docker 镜像...$(NC)"
	@docker compose pull
	@docker compose --profile init up runtime-init --remove-orphans
	@echo "$(GREEN)镜像拉取完成$(NC)"

# 启动服务
start: ## 启动服务
	@./scripts/start.sh

# 开发环境启动
dev: ## 启动开发环境
	@./scripts/start.sh --env dev

# 生产环境启动
prod: ## 启动生产环境
	@./scripts/start.sh --env prod

# 停止服务
stop: ## 停止服务
	@./scripts/stop.sh

# 重启服务
restart: ## 重启服务
	@echo "$(BLUE)重启 OpenHands 服务...$(NC)"
	@docker compose restart
	@echo "$(GREEN)服务重启完成$(NC)"

# 查看日志
logs: ## 查看日志
	@./scripts/logs.sh

# 实时日志
logs-f: ## 实时查看日志
	@./scripts/logs.sh --follow

# 查看状态
status: ## 查看服务状态
	@echo "$(BLUE)服务状态:$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(BLUE)网络状态:$(NC)"
	@docker network ls | grep openhands || echo "无 OpenHands 网络"
	@echo ""
	@echo "$(BLUE)卷状态:$(NC)"
	@docker volume ls | grep openhands || echo "无 OpenHands 卷"

# 进入容器
shell: ## 进入 OpenHands 容器
	@docker compose exec openhands bash

# 清理
clean: ## 清理所有资源 (包括数据卷)
	@echo "$(RED)警告: 这将删除所有数据!$(NC)"
	@read -p "确认继续? (y/N): " confirm && [ "$$confirm" = "y" ]
	@./scripts/stop.sh --volumes --cleanup
	@docker volume rm openhands-data 2>/dev/null || true
	@echo "$(GREEN)清理完成$(NC)"

# 备份
backup: ## 备份数据
	@echo "$(BLUE)备份 OpenHands 数据...$(NC)"
	@mkdir -p backups
	@docker run --rm -v openhands-data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/openhands-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@echo "$(GREEN)备份完成$(NC)"

# 恢复
restore: ## 恢复数据 (需要指定备份文件: make restore BACKUP=filename)
	@if [ -z "$(BACKUP)" ]; then echo "$(RED)请指定备份文件: make restore BACKUP=filename$(NC)"; exit 1; fi
	@echo "$(BLUE)恢复 OpenHands 数据...$(NC)"
	@docker run --rm -v openhands-data:/data -v $(PWD)/backups:/backup alpine tar xzf /backup/$(BACKUP) -C /data
	@echo "$(GREEN)恢复完成$(NC)"

# 更新
update: ## 更新到最新版本
	@echo "$(BLUE)更新 OpenHands...$(NC)"
	@docker compose pull
	@docker compose up -d
	@echo "$(GREEN)更新完成$(NC)"

# 健康检查
health: ## 检查服务健康状态
	@echo "$(BLUE)检查服务健康状态...$(NC)"
	@curl -f http://localhost:3000/api/health && echo "$(GREEN)服务正常$(NC)" || echo "$(RED)服务异常$(NC)"

# 监控
monitor: ## 监控资源使用情况
	@echo "$(BLUE)资源使用情况:$(NC)"
	@docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"