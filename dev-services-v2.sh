#!/bin/bash

# Blinko 开发环境服务管理脚本
# 支持最小配置（仅PostgreSQL）和完整配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
MINIMAL_COMPOSE_FILE="docker-compose.minimal.yml"
FULL_COMPOSE_FILE="docker-compose.dev.yml"

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

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
}

# 检查端口占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "端口 $port 已被占用"
        return 1
    fi
    return 0
}

# 启动服务
start_services() {
    local mode=$1
    local compose_file=""
    
    if [ "$mode" == "minimal" ]; then
        compose_file=$MINIMAL_COMPOSE_FILE
        log_info "启动最小开发环境（仅 PostgreSQL）..."
        
        # 检查 PostgreSQL 端口
        if ! check_port 5432; then
            log_error "PostgreSQL 端口 5432 被占用，请先停止其他服务"
            exit 1
        fi
    elif [ "$mode" == "full" ]; then
        compose_file=$FULL_COMPOSE_FILE
        log_info "启动完整开发环境..."
        
        # 检查所有端口
        for port in 5432 6379 9000 9001 1025 8025; do
            if ! check_port $port; then
                log_error "端口 $port 被占用，请先停止其他服务"
                exit 1
            fi
        done
    else
        log_error "无效的模式: $mode"
        show_usage
        exit 1
    fi
    
    if [ ! -f "$compose_file" ]; then
        log_error "配置文件 $compose_file 不存在"
        exit 1
    fi
    
    docker-compose -f "$compose_file" up -d
    
    log_success "服务启动成功！"
    show_services_info "$mode"
}

# 停止服务
stop_services() {
    local mode=$1
    local compose_file=""
    
    if [ "$mode" == "minimal" ]; then
        compose_file=$MINIMAL_COMPOSE_FILE
        log_info "停止最小开发环境..."
    elif [ "$mode" == "full" ]; then
        compose_file=$FULL_COMPOSE_FILE
        log_info "停止完整开发环境..."
    else
        log_error "无效的模式: $mode"
        show_usage
        exit 1
    fi
    
    if [ ! -f "$compose_file" ]; then
        log_error "配置文件 $compose_file 不存在"
        exit 1
    fi
    
    docker-compose -f "$compose_file" down
    log_success "服务已停止"
}

# 显示服务信息
show_services_info() {
    local mode=$1
    
    echo -e "\n${GREEN}=== 服务信息 ===${NC}"
    
    if [ "$mode" == "minimal" ]; then
        echo -e "${BLUE}PostgreSQL:${NC}"
        echo -e "  连接字符串: ${YELLOW}postgresql://postgres:password@localhost:5432/blinko${NC}"
        echo -e "  用户名: ${YELLOW}postgres${NC}"
        echo -e "  密码: ${YELLOW}password${NC}"
        echo -e "  数据库: ${YELLOW}blinko${NC}"
        echo -e "  端口: ${YELLOW}5432${NC}"
        
        echo -e "\n${GREEN}环境变量设置:${NC}"
        echo -e "export DATABASE_URL=\"postgresql://postgres:password@localhost:5432/blinko\""
    elif [ "$mode" == "full" ]; then
        echo -e "${BLUE}PostgreSQL:${NC}"
        echo -e "  连接字符串: ${YELLOW}postgresql://postgres:password@localhost:5432/blinko${NC}"
        echo -e "  管理界面: ${YELLOW}http://localhost:5432${NC}"
        
        echo -e "\n${BLUE}Redis:${NC}"
        echo -e "  连接字符串: ${YELLOW}redis://localhost:6379${NC}"
        
        echo -e "\n${BLUE}MinIO (S3):${NC}"
        echo -e "  控制台: ${YELLOW}http://localhost:9001${NC}"
        echo -e "  API端点: ${YELLOW}http://localhost:9000${NC}"
        echo -e "  用户名: ${YELLOW}minioadmin${NC}"
        echo -e "  密码: ${YELLOW}minioadmin${NC}"
        
        echo -e "\n${BLUE}MailHog:${NC}"
        echo -e "  Web界面: ${YELLOW}http://localhost:8025${NC}"
        echo -e "  SMTP端口: ${YELLOW}1025${NC}"
    fi
    
    echo -e "\n${GREEN}检查服务状态:${NC}"
    echo -e "  docker-compose -f $([[ \"$mode\" == \"minimal\" ]] && echo \"$MINIMAL_COMPOSE_FILE\" || echo \"$FULL_COMPOSE_FILE\") ps"
    
    echo -e "\n${GREEN}查看日志:${NC}"
    echo -e "  docker-compose -f $([[ \"$mode\" == \"minimal\" ]] && echo \"$MINIMAL_COMPOSE_FILE\" || echo \"$FULL_COMPOSE_FILE\") logs -f"
}

# 显示使用说明
show_usage() {
    echo -e "${GREEN}Blinko 开发环境管理脚本${NC}"
    echo ""
    echo -e "${BLUE}用法:${NC}"
    echo -e "  $0 {minimal|full} {start|stop|restart|status}"
    echo ""
    echo -e "${BLUE}模式:${NC}"
    echo -e "  ${YELLOW}minimal${NC}  - 最小环境（仅 PostgreSQL）"
    echo -e "  ${YELLOW}full${NC}     - 完整环境（PostgreSQL + Redis + MinIO + MailHog）"
    echo ""
    echo -e "${BLUE}操作:${NC}"
    echo -e "  ${YELLOW}start${NC}    - 启动服务"
    echo -e "  ${YELLOW}stop${NC}     - 停止服务"
    echo -e "  ${YELLOW}restart${NC}  - 重启服务"
    echo -e "  ${YELLOW}status${NC}   - 查看服务状态"
    echo ""
    echo -e "${BLUE}示例:${NC}"
    echo -e "  $0 minimal start    # 启动最小环境"
    echo -e "  $0 full start       # 启动完整环境"
    echo -e "  $0 minimal stop     # 停止最小环境"
    echo -e "  $0 full status      # 查看完整环境状态"
    echo ""
    echo -e "${GREEN}推荐使用最小环境进行日常开发！${NC}"
}

# 检查服务状态
check_status() {
    local mode=$1
    local compose_file=""
    
    if [ "$mode" == "minimal" ]; then
        compose_file=$MINIMAL_COMPOSE_FILE
    elif [ "$mode" == "full" ]; then
        compose_file=$FULL_COMPOSE_FILE
    else
        log_error "无效的模式: $mode"
        show_usage
        exit 1
    fi
    
    if [ ! -f "$compose_file" ]; then
        log_error "配置文件 $compose_file 不存在"
        exit 1
    fi
    
    log_info "检查 $mode 环境服务状态..."
    docker-compose -f "$compose_file" ps
    
    echo ""
    show_services_info "$mode"
}

# 主函数
main() {
    if [ $# -lt 2 ]; then
        show_usage
        exit 1
    fi
    
    check_docker
    
    local mode=$1
    local action=$2
    
    case $action in
        start)
            start_services "$mode"
            ;;
        stop)
            stop_services "$mode"
            ;;
        restart)
            stop_services "$mode"
            sleep 2
            start_services "$mode"
            ;;
        status)
            check_status "$mode"
            ;;
        *)
            log_error "无效的操作: $action"
            show_usage
            exit 1
            ;;
    esac
}

# 如果没有参数，显示使用说明
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

# 执行主函数
main "$@"
