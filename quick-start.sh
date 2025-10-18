#!/bin/bash

# QLORAX Quick Start Script
# One-command setup for QLORAX Docker deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}        QLORAX Quick Start Setup          ${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_docker() {
    print_info "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        echo "Please install Docker from: https://docker.com/get-started"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running"
        echo "Please start Docker Desktop or Docker daemon"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        echo "Please install Docker Compose"
        exit 1
    fi
    
    print_success "Docker is ready"
}

setup_environment() {
    print_info "Setting up environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        cp .env.example .env
        print_success "Created .env file from template"
    else
        print_info ".env file already exists"
    fi
    
    # Create necessary directories
    mkdir -p data models outputs logs
    print_success "Created necessary directories"
}

build_and_start() {
    print_info "Building and starting QLORAX..."
    
    # Build images
    docker-compose build
    
    # Start services
    docker-compose up -d
    
    print_success "QLORAX services started"
}

wait_for_services() {
    print_info "Waiting for services to be ready..."
    
    # Wait for API
    for i in {1..60}; do
        if curl -s -f http://localhost:8000/health >/dev/null 2>&1; then
            print_success "FastAPI is ready"
            break
        fi
        
        if [ $i -eq 60 ]; then
            print_warning "API took longer than expected to start"
            break
        fi
        
        sleep 2
    done
    
    # Wait for Gradio
    for i in {1..30}; do
        if curl -s -f http://localhost:7860 >/dev/null 2>&1; then
            print_success "Gradio interface is ready"
            break
        fi
        
        if [ $i -eq 30 ]; then
            print_warning "Gradio took longer than expected to start"
            break
        fi
        
        sleep 2
    done
}

show_status() {
    print_info "Service status:"
    docker-compose ps
    
    echo ""
    print_info "Health check:"
    if curl -s -f http://localhost:8000/health >/dev/null 2>&1; then
        print_success "API health check passed"
    else
        print_warning "API health check failed"
    fi
}

show_access_info() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}         QLORAX is Ready! 🚀              ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    echo -e "${GREEN}Access your QLORAX platform:${NC}"
    echo -e "  • Web Interface: ${YELLOW}http://localhost:7860${NC}"
    echo -e "  • API Docs:      ${YELLOW}http://localhost:8000/docs${NC}"
    echo -e "  • Health Check:  ${YELLOW}http://localhost:8000/health${NC}"
    echo ""
    echo -e "${GREEN}Management commands:${NC}"
    echo -e "  • View logs:     ${YELLOW}docker/manage.sh logs${NC}"
    echo -e "  • Stop services: ${YELLOW}docker/manage.sh stop${NC}"
    echo -e "  • Restart:       ${YELLOW}docker/manage.sh restart${NC}"
    echo -e "  • Enter shell:   ${YELLOW}docker/manage.sh shell${NC}"
    echo ""
    echo -e "${GREEN}Training commands:${NC}"
    echo -e "  • Start training: ${YELLOW}docker/manage.sh train${NC}"
    echo -e "  • Run demo:       ${YELLOW}docker/manage.sh demo${NC}"
    echo ""
    echo -e "${BLUE}============================================${NC}"
}

main() {
    print_header
    
    # Check requirements
    check_docker
    
    # Setup environment
    setup_environment
    
    # Build and start
    build_and_start
    
    # Wait for services
    wait_for_services
    
    # Show status
    show_status
    
    # Show access information
    show_access_info
}

# Handle script arguments
case "${1:-setup}" in
    "setup"|"start")
        main
        ;;
    "status")
        show_status
        ;;
    "info")
        show_access_info
        ;;
    "help"|"--help"|"-h")
        echo "QLORAX Quick Start Script"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  setup    Complete setup and start (default)"
        echo "  start    Same as setup"
        echo "  status   Show current status"
        echo "  info     Show access information"
        echo "  help     Show this help"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac