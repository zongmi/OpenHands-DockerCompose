#!/bin/bash

# OpenHands 日志查看脚本

set -e

# 颜色定义
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 查看日志
view_logs() {
    local service=${1:-""}
    local follow=${2:-false}
    local tail_lines=${3:-100}
    
    cd "$PROJECT_DIR"
    
    if [ "$follow" = true ]; then
        if [ -n "$service" ]; then
            log_info "实时查看 $service 服务日志..."
            docker compose logs -f --tail="$tail_lines" "$service"
        else
            log_info "实时查看所有服务日志..."
            docker compose logs -f --tail="$tail_lines"
        fi
    else
        if [ -n "$service" ]; then
            log_info "查看 $service 服务日志 (最近 $tail_lines 行)..."
            docker compose logs --tail="$tail_lines" "$service"
        else
            log_info "查看所有服务日志 (最近 $tail_lines 行)..."
            docker compose logs --tail="$tail_lines"
        fi
    fi
}

# 主函数
main() {
    echo "========================================="
    echo "       OpenHands Docker 日志查看"
    echo "========================================="
    echo ""
    
    # 解析参数
    local service=""
    local follow=false
    local tail_lines=100
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--service)
                service="$2"
                shift 2
                ;;
            -f|--follow)
                follow=true
                shift
                ;;
            -n|--tail)
                tail_lines="$2"
                shift 2
                ;;
            -h|--help)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  -s, --service NAME 指定服务名称 (openhands|nginx)"
                echo "  -f, --follow       实时跟踪日志"
                echo "  -n, --tail NUM     显示最近 NUM 行日志 (默认: 100)"
                echo "  -h, --help         显示帮助信息"
                echo ""
                echo "示例:"
                echo "  $0                 # 查看所有服务日志"
                echo "  $0 -f              # 实时跟踪所有服务日志"
                echo "  $0 -s openhands    # 查看 openhands 服务日志"
                echo "  $0 -s openhands -f # 实时跟踪 openhands 服务日志"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    # 查看日志
    view_logs "$service" "$follow" "$tail_lines"
}

# 运行主函数
main "$@"