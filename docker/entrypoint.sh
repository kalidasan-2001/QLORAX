#!/bin/bash

# QLORAX Docker Entrypoint Script
# Handles different service startup modes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       QLORAX Container Starting       ${NC}"
echo -e "${BLUE}========================================${NC}"

# Environment setup
export PYTHONPATH=/app:$PYTHONPATH
export TRANSFORMERS_CACHE=/app/models/.cache
export HF_HOME=/app/models/.cache

# Create cache directories
mkdir -p /app/models/.cache
mkdir -p /app/logs
mkdir -p /app/temp

# Function to wait for services
wait_for_service() {
    local host=$1
    local port=$2
    local timeout=${3:-30}
    
    echo -e "${BLUE}Waiting for $host:$port...${NC}"
    
    for i in $(seq $timeout); do
        if nc -z "$host" "$port" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $host:$port is ready${NC}"
            return 0
        fi
        sleep 1
    done
    
    echo -e "${YELLOW}⚠ $host:$port not ready after ${timeout}s${NC}"
    return 1
}

# Function to check Python environment
check_python_env() {
    echo -e "${BLUE}Checking Python environment...${NC}"
    
    python --version
    
    # Check critical packages
    python -c "import torch; print(f'PyTorch: {torch.__version__}')" 2>/dev/null || echo -e "${YELLOW}⚠ PyTorch not available${NC}"
    python -c "import transformers; print(f'Transformers: {transformers.__version__}')" 2>/dev/null || echo -e "${YELLOW}⚠ Transformers not available${NC}"
    python -c "import peft; print(f'PEFT: {peft.__version__}')" 2>/dev/null || echo -e "${YELLOW}⚠ PEFT not available${NC}"
    
    echo -e "${GREEN}✓ Python environment ready${NC}"
}

# Function to setup directories
setup_directories() {
    echo -e "${BLUE}Setting up directories...${NC}"
    
    # Ensure required directories exist
    for dir in data models outputs logs temp checkpoints; do
        if [ ! -d "/app/$dir" ]; then
            mkdir -p "/app/$dir"
            echo -e "${GREEN}✓ Created /app/$dir${NC}"
        fi
    done
}

# Main execution
echo -e "${BLUE}Environment: ${QLORAX_ENV:-production}${NC}"
echo -e "${BLUE}Command: $@${NC}"

# Setup
check_python_env
setup_directories

# Handle different startup modes
case "${1:-api}" in
    "api")
        echo -e "${GREEN}Starting FastAPI server...${NC}"
        exec python -m uvicorn app.api:app --host 0.0.0.0 --port 8000 --workers 1
        ;;
    
    "gradio")
        echo -e "${GREEN}Starting Gradio interface...${NC}"
        exec python app/gradio_app.py
        ;;
    
    "train")
        echo -e "${GREEN}Starting training...${NC}"
        exec python scripts/train_production.py "${@:2}"
        ;;
    
    "demo")
        echo -e "${GREEN}Starting demo...${NC}"
        exec python complete_demo.py
        ;;
    
    "jupyter")
        echo -e "${GREEN}Starting Jupyter notebook...${NC}"
        exec jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''
        ;;
    
    "bash")
        echo -e "${GREEN}Starting interactive shell...${NC}"
        exec /bin/bash
        ;;
    
    "health")
        echo -e "${GREEN}Running health check...${NC}"
        python -c "
import requests
import sys
try:
    response = requests.get('http://localhost:8000/health', timeout=5)
    if response.status_code == 200:
        print('✓ Health check passed')
        sys.exit(0)
    else:
        print('✗ Health check failed')
        sys.exit(1)
except Exception as e:
    print(f'✗ Health check error: {e}')
    sys.exit(1)
"
        ;;
    
    "test")
        echo -e "${GREEN}Running tests...${NC}"
        exec python -m pytest tests/ -v "${@:2}"
        ;;
    
    *)
        echo -e "${GREEN}Executing custom command: $@${NC}"
        exec "$@"
        ;;
esac