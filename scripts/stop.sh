#!/bin/bash

# OpenHands 停止脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 停止服务
stop_services() {
    local remove_volumes=${1:-false}
    
    log_info "停止 OpenHands 服务..."
    
    cd "$PROJECT_DIR"
    
    if [ "$remove_volumes" = true ]; then
        log_warning "将删除所有数据卷..."
        docker compose down -v --remove-orphans
    else
        docker compose down --remove-orphans
    fi
    
    log_success "服务已停止"
}

# 清理资源
cleanup_resources() {
    log_info "清理 Docker 资源..."
    
    # 清理未使用的容器
    docker container prune -f
    
    # 清理未使用的镜像
    docker image prune -f
    
    # 清理未使用的网络
    docker network prune -f
    
    log_success "资源清理完成"
}

# 显示状态
show_status() {
    log_info "当前状态:"
    cd "$PROJECT_DIR"
    docker compose ps -a
}

# 主函数
main() {
    echo "========================================="
    echo "       OpenHands Docker 停止脚本"
    echo "========================================="
    echo ""
    
    # 解析参数
    local remove_volumes=false
    local cleanup=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--volumes)
                remove_volumes=true
                shift
                ;;
            -c|--cleanup)
                cleanup=true
                shift
                ;;
            -h|--help)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  -v, --volumes      同时删除数据卷"
                echo "  -c, --cleanup      清理未使用的 Docker 资源"
                echo "  -h, --help         显示帮助信息"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    # 执行停止流程
    stop_services "$remove_volumes"
    
    if [ "$cleanup" = true ]; then
        cleanup_resources
    fi
    
    show_status
    log_success "OpenHands 已停止"
}

# 运行主函数
main "$@"