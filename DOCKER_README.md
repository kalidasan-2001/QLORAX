# 🚀 QLORAX - Complete Docker Integration

## 🐳 Docker Quick Start

### One-Command Setup (Recommended)

**Windows:**
```cmd
quick-start.bat
```

**Linux/Mac:**
```bash
bash quick-start.sh
```

This will automatically:
- ✅ Check Docker installation
- ✅ Set up environment
- ✅ Build Docker images
- ✅ Start all services
- ✅ Verify everything is working

### Manual Setup

1. **Prerequisites**
   ```bash
   # Ensure Docker and Docker Compose are installed
   docker --version
   docker-compose --version
   ```

2. **Environment Setup**
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Create directories
   mkdir -p data models outputs logs
   ```

3. **Build and Start**
   ```bash
   # Build images
   docker-compose build
   
   # Start services
   docker-compose up -d
   ```

4. **Verify Services**
   ```bash
   # Check status
   docker-compose ps
   
   # Health check
   curl http://localhost:8000/health
   ```

## 🌐 Access Your QLORAX Platform

Once running, access these URLs:

- **🎯 Main Interface**: http://localhost:7860
- **📚 API Documentation**: http://localhost:8000/docs
- **🏥 Health Check**: http://localhost:8000/health
- **🔧 Raw API**: http://localhost:8000

## ⚙️ Management Commands

### Basic Operations
```bash
# Windows
docker\manage.bat [command]

# Linux/Mac
bash docker/manage.sh [command]
```

**Available Commands:**
- `setup` - First time setup
- `start` - Start services
- `stop` - Stop services
- `restart` - Restart services
- `status` - Show service status
- `logs` - View logs
- `build` - Build images
- `cleanup` - Clean up Docker resources

### Training & Development
```bash
# Start training
docker\manage.bat train

# Run interactive demo
docker\manage.bat demo

# Enter container shell
docker\manage.bat shell

# View real-time logs
docker\manage.bat logs qlorax
```

## 🔧 Service Profiles

### Default Profile
```bash
docker\manage.bat start
```
- FastAPI (port 8000)
- Gradio (port 7860)
- Basic QLORAX services

### Development Profile
```bash
docker\manage.bat start dev
```
- Development environment with hot reload
- Ports: 8001 (FastAPI), 7861 (Gradio)
- Full project mounted as volume

### Full Stack Profile
```bash
docker\manage.bat start full
```
- All default services
- Redis caching (port 6379)

### Monitoring Profile
```bash
docker\manage.bat start monitoring
```
- All default services
- Prometheus (port 9090)
- Grafana (port 3000, admin/admin)

## 📊 Web Interface Features

The Gradio interface at http://localhost:7860 includes:

### 💬 Chat Tab
- Interactive chat with your fine-tuned model
- Adjustable generation parameters (temperature, top-p, max length)
- Real-time model status display
- Conversation history

### 🤖 Model Management Tab
- Load trained models or base models
- Browse available models
- Switch between different model checkpoints
- Model status monitoring

### 🏋️ Training Tab
- Start training with custom configurations
- Monitor training progress
- View training logs and status
- Background training execution

### ⚙️ System Tab
- Health status monitoring
- System resource usage
- API endpoint information
- Configuration details

## 🔗 API Endpoints

### Core Endpoints
- `GET /` - API information
- `GET /health` - Health check
- `POST /chat` - Chat with model
- `GET /model_status` - Model status
- `POST /load_model` - Load model

### Training Endpoints
- `POST /train` - Start training
- `GET /train/status` - Training status

### Utility Endpoints
- `GET /models` - List available models
- `GET /metrics` - System metrics

## 🔒 Environment Configuration

Copy `.env.example` to `.env` and customize:

```env
# Application settings
QLORAX_ENV=production
MODEL_NAME=microsoft/DialoGPT-medium

# Resource settings
CUDA_VISIBLE_DEVICES=  # Empty for CPU
MEMORY_LIMIT=4g
CPU_LIMIT=2.0

# API settings
API_HOST=0.0.0.0
API_PORT=8000
SECRET_KEY=your-secret-key-here
```

## 💾 Data Persistence

Docker volumes automatically mount:
- `./data` → `/app/data` (training data)
- `./models` → `/app/models` (model files)
- `./outputs` → `/app/outputs` (training outputs)
- `./logs` → `/app/logs` (application logs)
- `./configs` → `/app/configs` (read-only configs)

## 🛠️ Development Workflow

1. **Start Development Environment**
   ```bash
   docker\manage.bat start dev
   ```

2. **Make Code Changes** (auto-reload enabled)

3. **Test Changes**
   ```bash
   # View logs
   docker\manage.bat logs qlorax-dev
   
   # Access dev interface
   # http://localhost:8001 (API)
   # http://localhost:7861 (Gradio)
   ```

4. **Run Training**
   ```bash
   docker\manage.bat train
   ```

5. **Test Demo**
   ```bash
   docker\manage.bat demo
   ```

## 📈 Monitoring & Observability

### Health Monitoring
```bash
# Automated health check
bash docker/health-check.sh

# Quick connectivity check
bash docker/health-check.sh quick

# Full system check
bash docker/health-check.sh full
```

### Monitoring Stack
```bash
# Start with monitoring
docker\manage.bat start monitoring

# Access monitoring tools
# Grafana: http://localhost:3000 (admin/admin)
# Prometheus: http://localhost:9090
```

## 💽 Backup & Recovery

### Create Backup
```bash
docker\manage.bat backup
```
Creates timestamped backup in `backups/` directory including:
- Training data
- Model files
- Training outputs
- Configuration files

### Restore Backup
```bash
docker\manage.bat restore backups/20240101_120000
```

## 🐛 Troubleshooting

### Common Issues

**Port Conflicts:**
```bash
# Check port usage
netstat -an | findstr "8000"

# Change ports in docker-compose.yml if needed
```

**Memory Issues:**
```bash
# Check container memory
docker stats

# Increase Docker memory limit in Docker Desktop
```

**Build Failures:**
```bash
# Clean rebuild
docker\manage.bat cleanup
docker\manage.bat build
```

**Service Not Ready:**
```bash
# Check logs
docker\manage.bat logs qlorax

# Health check
curl http://localhost:8000/health

# Enter container for debugging
docker\manage.bat shell
```

### Debug Mode

Enter container for debugging:
```bash
# Interactive shell
docker\manage.bat shell

# Check Python environment
python --version
pip list

# Test model loading
python -c "from transformers import AutoTokenizer; print('OK')"
```

## 🔄 CI/CD Integration

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

## 🚀 Production Deployment

### Resource Optimization
```yaml
# In docker-compose.yml
services:
  qlorax:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'
```

### GPU Support
```yaml
# Add to docker-compose.yml for GPU
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

### Security
- Use proper API keys in `.env`
- Enable Docker secrets for production
- Restrict network access
- Regular security updates

## 📚 Additional Resources

- **Docker Guide**: `DOCKER_GUIDE.md` - Comprehensive Docker documentation
- **API Documentation**: http://localhost:8000/docs (when running)
- **Training Guide**: `COMPREHENSIVE_GUIDE.md`
- **Error Resolution**: `ERROR_RESOLUTION.md`

## 🆘 Support

1. **Check Health**: `bash docker/health-check.sh`
2. **View Logs**: `docker\manage.bat logs`
3. **Clean Reset**: `docker\manage.bat cleanup && docker\manage.bat setup`
4. **Container Debug**: `docker\manage.bat shell`

---

## 🎯 Complete Feature Matrix

| Feature | Status | Docker Support |
|---------|--------|----------------|
| QLoRA Fine-tuning | ✅ | ✅ |
| Model Inference | ✅ | ✅ |
| Web Interface | ✅ | ✅ |
| API Server | ✅ | ✅ |
| Training Pipeline | ✅ | ✅ |
| Evaluation Suite | ✅ | ✅ |
| Model Management | ✅ | ✅ |
| Real-time Chat | ✅ | ✅ |
| Health Monitoring | ✅ | ✅ |
| Data Persistence | ✅ | ✅ |
| Backup/Recovery | ✅ | ✅ |
| Development Mode | ✅ | ✅ |
| Production Ready | ✅ | ✅ |

**QLORAX is now fully containerized without breaking any functionality! 🎉**