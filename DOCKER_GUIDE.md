# QLORAX Docker Integration Guide

## Quick Start

### 1. First Time Setup
```bash
# On Windows
docker\manage.bat setup

# On Linux/Mac
bash docker/manage.sh setup
```

This will:
- Check Docker requirements
- Create necessary directories
- Build Docker images
- Start all services

### 2. Access Your Application
- **FastAPI**: http://localhost:8000
- **Gradio Interface**: http://localhost:7860
- **API Documentation**: http://localhost:8000/docs

## Available Commands

### Basic Operations
```bash
# Start services
docker\manage.bat start

# Stop services
docker\manage.bat stop

# Restart services
docker\manage.bat restart

# Check status
docker\manage.bat status

# View logs
docker\manage.bat logs
docker\manage.bat logs qlorax  # specific service
```

### Development & Training
```bash
# Run training
docker\manage.bat train

# Run interactive demo
docker\manage.bat demo

# Enter container shell
docker\manage.bat shell

# Build images
docker\manage.bat build
```

### Data Management
```bash
# Create backup
docker\manage.bat backup

# Restore from backup
docker\manage.bat restore backups\20240101_120000
```

### Advanced Profiles
```bash
# Development environment
docker\manage.bat start dev

# Full stack with Redis
docker\manage.bat start full

# With monitoring (Prometheus + Grafana)
docker\manage.bat start monitoring
```

## Service Profiles

### Default Profile
- QLORAX main application
- FastAPI (port 8000)
- Gradio (port 7860)

### Development Profile (`dev`)
- Development environment with hot reload
- Full project mounted as volume
- Ports: 8001 (FastAPI), 7861 (Gradio)

### Full Profile (`full`)
- All default services
- Redis caching (port 6379)

### Monitoring Profile (`monitoring`)
- All default services
- Prometheus (port 9090)
- Grafana (port 3000, admin/admin)

## Volume Mounts

The following directories are mounted as volumes:
- `./data` → `/app/data` (training data)
- `./models` → `/app/models` (model files)
- `./outputs` → `/app/outputs` (training outputs)
- `./logs` → `/app/logs` (application logs)
- `./configs` → `/app/configs` (configuration files, read-only)

## Environment Configuration

Copy `.env.example` to `.env` and modify as needed:
```bash
cp .env.example .env
```

Key environment variables:
- `QLORAX_ENV`: Environment (production/development)
- `CUDA_VISIBLE_DEVICES`: GPU configuration (empty for CPU)
- `WANDB_DISABLED`: Disable Weights & Biases logging
- `API_HOST`/`API_PORT`: API server configuration

## Health Checks

### Automated Health Check
```bash
# On Windows
bash docker/health-check.sh

# Full check (default)
bash docker/health-check.sh full

# Quick check
bash docker/health-check.sh quick
```

### Manual Health Check
Visit: http://localhost:8000/health

## Troubleshooting

### Common Issues

1. **Port conflicts**
   ```bash
   # Check what's using the ports
   netstat -an | findstr "8000\|7860"
   
   # Stop conflicting services or change ports in docker-compose.yml
   ```

2. **Memory issues**
   ```bash
   # Check container memory usage
   docker stats
   
   # Increase Docker Desktop memory limit
   # Docker Desktop → Settings → Resources → Memory
   ```

3. **Permission issues**
   ```bash
   # Ensure directories exist and are writable
   mkdir data models outputs logs
   ```

4. **Build failures**
   ```bash
   # Clean build
   docker\manage.bat cleanup
   docker\manage.bat build
   ```

### Log Analysis
```bash
# View application logs
docker\manage.bat logs qlorax

# Follow logs in real-time
docker-compose logs -f qlorax

# Container-specific logs
docker logs qlorax-app
```

### Container Debugging
```bash
# Enter running container
docker\manage.bat shell

# Or directly
docker-compose exec qlorax bash

# Check container processes
docker-compose exec qlorax ps aux

# Check Python environment
docker-compose exec qlorax python --version
docker-compose exec qlorax pip list
```

## Performance Optimization

### CPU Optimization
- The default configuration is optimized for CPU-only execution
- Adjust `OMP_NUM_THREADS` in docker-compose.yml if needed
- Consider increasing container memory limits

### GPU Support
To enable GPU support:
1. Install NVIDIA Docker runtime
2. Modify docker-compose.yml:
   ```yaml
   services:
     qlorax:
       deploy:
         resources:
           reservations:
             devices:
               - driver: nvidia
                 count: 1
                 capabilities: [gpu]
   ```
3. Update environment variables:
   ```bash
   CUDA_VISIBLE_DEVICES=0
   ```

## Security Considerations

1. **API Keys**: Set proper API keys in `.env`
2. **Network**: Services are isolated in `qlorax-network`
3. **Volumes**: Configs mounted as read-only
4. **Secrets**: Use Docker secrets for production

## Production Deployment

### Resource Limits
Add to docker-compose.yml:
```yaml
services:
  qlorax:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'
        reservations:
          memory: 2G
          cpus: '1.0'
```

### Load Balancing
For multiple instances:
```yaml
services:
  qlorax:
    scale: 3
  
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
```

### Monitoring Setup
```bash
# Start with monitoring
docker\manage.bat start monitoring

# Access Grafana
# URL: http://localhost:3000
# Login: admin/admin
```

## Backup & Recovery

### Automated Backups
```bash
# Create timestamped backup
docker\manage.bat backup

# Backups are stored in backups/ directory
```

### Backup Contents
- Training data (`data/`)
- Model files (`models/`)
- Training outputs (`outputs/`)
- Configuration files (`configs/`)

### Recovery
```bash
# Restore from specific backup
docker\manage.bat restore backups\20240101_120000
```

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: QLORAX Docker Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and test
        run: |
          docker-compose build
          docker-compose up -d
          bash docker/health-check.sh quick
```

## Development Workflow

1. **Start development environment**
   ```bash
   docker\manage.bat start dev
   ```

2. **Make changes** (files are mounted, changes reflect immediately)

3. **Test changes**
   ```bash
   docker\manage.bat logs qlorax-dev
   ```

4. **Run training**
   ```bash
   docker\manage.bat train
   ```

5. **Test demo**
   ```bash
   docker\manage.bat demo
   ```

## Support

- Check logs: `docker\manage.bat logs`
- Health check: `bash docker/health-check.sh`
- Container access: `docker\manage.bat shell`
- Clean reset: `docker\manage.bat cleanup && docker\manage.bat setup`