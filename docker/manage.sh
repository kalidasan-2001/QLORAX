#!/bin/bash

# QLORAX Docker Management Script
# This script provides easy management of the QLORAX Docker environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="qlorax"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}           QLORAX Docker Manager           ${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_requirements() {
    print_info "Checking requirements..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        print_error "docker-compose.yml not found in current directory."
        exit 1
    fi
    
    print_success "All requirements met"
}

prepare_directories() {
    print_info "Preparing directories..."
    
    # Create necessary directories
    mkdir -p data models outputs logs docker/grafana docker/prometheus
    
    # Set proper permissions
    chmod 755 data models outputs logs
    
    print_success "Directories prepared"
}

build_images() {
    print_info "Building Docker images..."
    docker-compose build --no-cache
    print_success "Images built successfully"
}

start_services() {
    local profile=${1:-""}
    
    print_info "Starting QLORAX services..."
    
    if [ -n "$profile" ]; then
        docker-compose --profile "$profile" up -d
    else
        docker-compose up -d
    fi
    
    print_success "Services started"
    print_info "FastAPI: http://localhost:8000"
    print_info "Gradio: http://localhost:7860"
    
    if [ "$profile" = "monitoring" ] || [ "$profile" = "full" ]; then
        print_info "Grafana: http://localhost:3000 (admin/admin)"
        print_info "Prometheus: http://localhost:9090"
    fi
    
    if [ "$profile" = "full" ]; then
        print_info "Redis: localhost:6379"
    fi
}

stop_services() {
    print_info "Stopping QLORAX services..."
    docker-compose down
    print_success "Services stopped"
}

restart_services() {
    print_info "Restarting QLORAX services..."
    docker-compose restart
    print_success "Services restarted"
}

show_logs() {
    local service=${1:-"qlorax"}
    print_info "Showing logs for $service..."
    docker-compose logs -f "$service"
}

show_status() {
    print_info "Service status:"
    docker-compose ps
    
    print_info "\nHealth checks:"
    docker-compose exec qlorax curl -f http://localhost:8000/health 2>/dev/null || print_warning "Health check failed"
}

cleanup() {
    print_info "Cleaning up Docker resources..."
    docker-compose down -v --remove-orphans
    docker system prune -f
    print_success "Cleanup completed"
}

backup_data() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    print_info "Creating backup in $backup_dir..."
    
    mkdir -p "$backup_dir"
    
    # Backup data, models, and outputs
    if [ -d "data" ]; then
        cp -r data "$backup_dir/"
    fi
    
    if [ -d "models" ]; then
        cp -r models "$backup_dir/"
    fi
    
    if [ -d "outputs" ]; then
        cp -r outputs "$backup_dir/"
    fi
    
    # Backup configuration
    cp -r configs "$backup_dir/" 2>/dev/null || true
    
    print_success "Backup created at $backup_dir"
}

restore_data() {
    local backup_dir=$1
    
    if [ -z "$backup_dir" ]; then
        print_error "Please specify backup directory"
        exit 1
    fi
    
    if [ ! -d "$backup_dir" ]; then
        print_error "Backup directory $backup_dir not found"
        exit 1
    fi
    
    print_info "Restoring from $backup_dir..."
    
    # Stop services first
    docker-compose down
    
    # Restore data
    if [ -d "$backup_dir/data" ]; then
        rm -rf data
        cp -r "$backup_dir/data" .
    fi
    
    if [ -d "$backup_dir/models" ]; then
        rm -rf models
        cp -r "$backup_dir/models" .
    fi
    
    if [ -d "$backup_dir/outputs" ]; then
        rm -rf outputs
        cp -r "$backup_dir/outputs" .
    fi
    
    print_success "Data restored from $backup_dir"
}

run_training() {
    print_info "Starting training in container..."
    docker-compose exec qlorax python scripts/train_production.py
}

run_demo() {
    print_info "Starting interactive demo..."
    docker-compose exec qlorax python complete_demo.py
}

enter_container() {
    print_info "Entering QLORAX container..."
    docker-compose exec qlorax bash
}

show_help() {
    print_header
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup                  Setup and start QLORAX (first time)"
    echo "  start [profile]        Start services (profiles: dev, full, monitoring)"
    echo "  stop                   Stop all services"
    echo "  restart                Restart all services"
    echo "  status                 Show service status"
    echo "  logs [service]         Show logs (default: qlorax)"
    echo "  build                  Build Docker images"
    echo "  train                  Run training in container"
    echo "  demo                   Run interactive demo"
    echo "  shell                  Enter container shell"
    echo "  backup                 Backup data and models"
    echo "  restore <backup_dir>   Restore from backup"
    echo "  cleanup                Clean up Docker resources"
    echo "  help                   Show this help"
    echo ""
    echo "Profiles:"
    echo "  default               Basic QLORAX services"
    echo "  dev                   Development environment"
    echo "  full                  Include Redis caching"
    echo "  monitoring            Include Prometheus + Grafana"
    echo ""
    echo "Examples:"
    echo "  $0 setup                    # First time setup"
    echo "  $0 start                    # Start basic services"
    echo "  $0 start monitoring         # Start with monitoring"
    echo "  $0 logs qlorax              # Show main service logs"
    echo "  $0 backup                   # Create backup"
}

# Main script logic
main() {
    case "${1:-help}" in
        setup)
            print_header
            check_requirements
            prepare_directories
            build_images
            start_services
            ;;
        start)
            check_requirements
            start_services "$2"
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2"
            ;;
        build)
            check_requirements
            build_images
            ;;
        train)
            run_training
            ;;
        demo)
            run_demo
            ;;
        shell)
            enter_container
            ;;
        backup)
            backup_data
            ;;
        restore)
            restore_data "$2"
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"