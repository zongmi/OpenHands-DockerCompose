#!/bin/bash

# OpenHands 启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查 Docker 和 Docker Compose
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装或不在 PATH 中"
        exit 1
    fi
    
    if ! command -v docker compose &> /dev/null; then
        log_error "Docker Compose V2 未安装或不在 PATH 中"
        exit 1
    fi
    
    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker 守护进程未运行"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 检查环境变量文件
check_env_file() {
    log_info "检查环境配置..."
    
    if [ ! -f "$PROJECT_DIR/.env" ]; then
        if [ -f "$PROJECT_DIR/.env.example" ]; then
            log_warning ".env 文件不存在，从 .env.example 复制..."
            cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
            log_warning "请编辑 .env 文件并设置您的 API 密钥"
        else
            log_error ".env 和 .env.example 文件都不存在"
            exit 1
        fi
    fi
    
    # 检查关键环境变量
    source "$PROJECT_DIR/.env"
    
    if [ -z "$LLM_API_KEY" ] || [ "$LLM_API_KEY" = "your-api-key-here" ]; then
        log_warning "请在 .env 文件中设置有效的 LLM_API_KEY"
    fi
    
    log_success "环境配置检查完成"
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    
    mkdir -p "$PROJECT_DIR/data"
    mkdir -p "$PROJECT_DIR/logs"
    mkdir -p "$PROJECT_DIR/workspace"
    mkdir -p "$PROJECT_DIR/trajectories"
    
    log_success "目录创建完成"
}

# 拉取镜像
pull_images() {
    log_info "拉取 Docker 镜像..."
    
    cd "$PROJECT_DIR"
    docker compose pull
    
    # 预拉取运行时镜像
    docker compose --profile init up runtime-init --remove-orphans
    
    log_success "镜像拉取完成"
}

# 启动服务
start_services() {
    local env_type=${1:-"default"}
    
    log_info "启动 OpenHands 服务 (环境: $env_type)..."
    
    cd "$PROJECT_DIR"
    
    case $env_type in
        "dev"|"development")
            docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
            ;;
        "prod"|"production")
            docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
            ;;
        *)
            docker compose up -d
            ;;
    esac
    
    log_success "服务启动完成"
}

# 等待服务就绪
wait_for_service() {
    log_info "等待服务就绪..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:3000/api/health &> /dev/null; then
            log_success "OpenHands 服务已就绪"
            return 0
        fi
        
        log_info "等待服务启动... ($attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    log_error "服务启动超时"
    return 1
}

# 显示状态
show_status() {
    log_info "服务状态:"
    cd "$PROJECT_DIR"
    docker compose ps
    
    echo ""
    log_info "访问地址:"
    echo "  Web UI: http://localhost:3000"
    echo ""
    log_info "有用的命令:"
    echo "  查看日志: $SCRIPT_DIR/logs.sh"
    echo "  停止服务: $SCRIPT_DIR/stop.sh"
    echo "  重启服务: docker compose restart"
}

# 主函数
main() {
    echo "========================================="
    echo "       OpenHands Docker 启动脚本"
    echo "========================================="
    echo ""
    
    # 解析参数
    local env_type="default"
    local skip_pull=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                env_type="$2"
                shift 2
                ;;
            --skip-pull)
                skip_pull=true
                shift
                ;;
            -h|--help)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  -e, --env TYPE     指定环境类型 (default|dev|prod)"
                echo "  --skip-pull        跳过镜像拉取"
                echo "  -h, --help         显示帮助信息"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    # 执行启动流程
    check_dependencies
    check_env_file
    create_directories
    
    if [ "$skip_pull" = false ]; then
        pull_images
    fi
    
    start_services "$env_type"
    
    if wait_for_service; then
        show_status
        log_success "OpenHands 启动完成！"
    else
        log_error "启动失败，请检查日志"
        cd "$PROJECT_DIR"
        docker compose logs --tail=50
        exit 1
    fi
}

# 运行主函数
main "$@"