# Multi-stage Dockerfile for QLORAX MLOps Platform
# Preserves all functionality while enabling containerization

# =============================================================================
# Stage 1: Base Python Environment
# =============================================================================
FROM python:3.11-slim as base

# Set environment variables for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    netcat-openbsd \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash --uid 1000 qlorax

# =============================================================================
# Stage 2: Dependencies Installation
# =============================================================================
FROM base as dependencies

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements-simple.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements-simple.txt

# Install PyTorch CPU-only (after initial deps to avoid conflicts)
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install additional ML packages
RUN pip install --no-cache-dir transformers peft datasets accelerate

# Install additional production dependencies
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn[standard] \
    gradio \
    gunicorn \
    psutil \
    python-multipart

# =============================================================================
# Stage 3: Application Setup
# =============================================================================
FROM dependencies as application

# Copy application code with proper ownership
COPY --chown=qlorax:qlorax . .

# Create necessary directories
RUN mkdir -p \
    models \
    data \
    results \
    logs \
    checkpoints \
    temp \
    && chown -R qlorax:qlorax /app

# Make scripts executable
RUN find scripts/ -name "*.py" -exec chmod +x {} \; && \
    find . -name "*.py" -exec chmod +x {} \;

# =============================================================================
# Stage 4: Development Environment
# =============================================================================
FROM application as development

# Install development dependencies
RUN pip install --no-cache-dir \
    jupyter \
    notebook \
    ipython \
    black \
    flake8 \
    pytest \
    pytest-cov

# Keep as root for development flexibility
USER root

# Set development environment
ENV QLORAX_ENV=development

# Default command for development
CMD ["python", "app/api.py", "--dev"]

# =============================================================================
# Stage 5: Production Ready
# =============================================================================
FROM application as production

# Switch to non-root user
USER qlorax

# Copy and setup entrypoint
COPY --chown=qlorax:qlorax docker/entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
USER qlorax

# Expose ports
EXPOSE 8000 7860 8888

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Set entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["api"]