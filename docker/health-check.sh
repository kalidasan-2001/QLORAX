#!/bin/bash

# QLORAX Docker Health Check Script
# This script validates the health of all QLORAX components

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local status=$1
    local message=$2
    
    case $status in
        "OK")
            echo -e "${GREEN}✓ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠ $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}✗ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ $message${NC}"
            ;;
    esac
}

check_docker() {
    print_status "INFO" "Checking Docker environment..."
    
    if ! docker --version >/dev/null 2>&1; then
        print_status "ERROR" "Docker is not available"
        return 1
    fi
    
    if ! docker-compose --version >/dev/null 2>&1; then
        print_status "ERROR" "Docker Compose is not available"
        return 1
    fi
    
    print_status "OK" "Docker environment is ready"
    return 0
}

check_containers() {
    print_status "INFO" "Checking container status..."
    
    local containers=$(docker-compose ps -q)
    if [ -z "$containers" ]; then
        print_status "ERROR" "No containers are running"
        return 1
    fi
    
    # Check main QLORAX container
    if docker-compose ps qlorax | grep -q "Up"; then
        print_status "OK" "QLORAX container is running"
    else
        print_status "ERROR" "QLORAX container is not running"
        return 1
    fi
    
    return 0
}

check_health_endpoint() {
    print_status "INFO" "Checking health endpoints..."
    
    # Wait for services to be ready
    sleep 5
    
    # Check FastAPI health
    if curl -f -s http://localhost:8000/health >/dev/null 2>&1; then
        print_status "OK" "FastAPI health endpoint is responding"
    else
        print_status "ERROR" "FastAPI health endpoint is not responding"
        return 1
    fi
    
    # Check if Gradio is accessible
    if curl -f -s http://localhost:7860 >/dev/null 2>&1; then
        print_status "OK" "Gradio interface is accessible"
    else
        print_status "WARNING" "Gradio interface is not accessible"
    fi
    
    return 0
}

check_volumes() {
    print_status "INFO" "Checking volume mounts..."
    
    # Check if important directories are mounted
    if docker-compose exec -T qlorax test -d /app/data; then
        print_status "OK" "Data volume is mounted"
    else
        print_status "WARNING" "Data volume might not be mounted correctly"
    fi
    
    if docker-compose exec -T qlorax test -d /app/models; then
        print_status "OK" "Models volume is mounted"
    else
        print_status "WARNING" "Models volume might not be mounted correctly"
    fi
    
    return 0
}

check_python_environment() {
    print_status "INFO" "Checking Python environment in container..."
    
    # Check Python version
    local python_version=$(docker-compose exec -T qlorax python --version 2>&1)
    if [[ $python_version == *"Python 3"* ]]; then
        print_status "OK" "Python environment: $python_version"
    else
        print_status "ERROR" "Python environment check failed"
        return 1
    fi
    
    # Check key packages
    if docker-compose exec -T qlorax python -c "import torch; print(f'PyTorch {torch.__version__}')" >/dev/null 2>&1; then
        local torch_version=$(docker-compose exec -T qlorax python -c "import torch; print(f'PyTorch {torch.__version__}')")
        print_status "OK" "$torch_version"
    else
        print_status "ERROR" "PyTorch is not available"
        return 1
    fi
    
    if docker-compose exec -T qlorax python -c "import transformers; print(f'Transformers {transformers.__version__}')" >/dev/null 2>&1; then
        local transformers_version=$(docker-compose exec -T qlorax python -c "import transformers; print(f'Transformers {transformers.__version__}')")
        print_status "OK" "$transformers_version"
    else
        print_status "ERROR" "Transformers is not available"
        return 1
    fi
    
    return 0
}

check_model_loading() {
    print_status "INFO" "Testing model loading..."
    
    # Test basic model loading
    if docker-compose exec -T qlorax python -c "
from transformers import AutoTokenizer, AutoModelForCausalLM
try:
    tokenizer = AutoTokenizer.from_pretrained('microsoft/DialoGPT-medium')
    print('Model loading test passed')
except Exception as e:
    print(f'Model loading test failed: {e}')
    exit(1)
" >/dev/null 2>&1; then
        print_status "OK" "Model loading test passed"
    else
        print_status "WARNING" "Model loading test failed (might need internet connection)"
    fi
    
    return 0
}

check_disk_space() {
    print_status "INFO" "Checking disk space..."
    
    # Check available disk space
    local disk_usage=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -lt 80 ]; then
        print_status "OK" "Disk usage: ${disk_usage}%"
    elif [ "$disk_usage" -lt 90 ]; then
        print_status "WARNING" "Disk usage: ${disk_usage}% (consider cleanup)"
    else
        print_status "ERROR" "Disk usage: ${disk_usage}% (critical)"
        return 1
    fi
    
    return 0
}

check_memory() {
    print_status "INFO" "Checking memory usage..."
    
    # Check container memory usage
    local memory_stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}" | grep qlorax)
    
    if [ -n "$memory_stats" ]; then
        print_status "OK" "Memory usage: $memory_stats"
    else
        print_status "WARNING" "Could not retrieve memory statistics"
    fi
    
    return 0
}

run_comprehensive_check() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}        QLORAX Health Check Report         ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    local overall_status=0
    
    # Run all checks
    check_docker || overall_status=1
    echo ""
    
    check_containers || overall_status=1
    echo ""
    
    check_health_endpoint || overall_status=1
    echo ""
    
    check_volumes || overall_status=1
    echo ""
    
    check_python_environment || overall_status=1
    echo ""
    
    check_model_loading || overall_status=1
    echo ""
    
    check_disk_space || overall_status=1
    echo ""
    
    check_memory || overall_status=1
    echo ""
    
    # Overall result
    echo -e "${BLUE}============================================${NC}"
    if [ $overall_status -eq 0 ]; then
        print_status "OK" "All health checks passed"
        echo -e "${GREEN}QLORAX is ready for use!${NC}"
    else
        print_status "WARNING" "Some health checks failed"
        echo -e "${YELLOW}Please review the issues above${NC}"
    fi
    echo -e "${BLUE}============================================${NC}"
    
    return $overall_status
}

# Main execution
if [ "${1:-full}" = "full" ]; then
    run_comprehensive_check
elif [ "$1" = "quick" ]; then
    check_docker && check_containers && check_health_endpoint
else
    echo "Usage: $0 [full|quick]"
    echo "  full  - Run comprehensive health check (default)"
    echo "  quick - Run basic connectivity check"
    exit 1
fi