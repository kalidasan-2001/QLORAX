# QLORAX GitHub Actions Deployment Guide

## 🚀 Quick Start with GitHub Actions

Your QLORAX project is now ready for GitHub Actions! Here's your step-by-step deployment plan:

### 1. 📤 Push to GitHub Repository

```bash
# Initialize git if not already done
git init
git add .
git commit -m "Initial QLORAX setup with GitHub Actions"

# Add your GitHub repository
git remote add origin https://github.com/YOUR_USERNAME/qlorax.git
git branch -M main
git push -u origin main
```

### 2. 🔧 Workflows Available

#### **Main CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
- ✅ Builds Docker images
- ✅ Runs comprehensive tests
- ✅ Security vulnerability scanning
- ✅ Deploys to production
- ✅ Optional model training

#### **Quick Testing** (`.github/workflows/quick-test.yml`)
- ⚡ Fast dependency checks
- ⚡ Import validation
- ⚡ Docker build verification

#### **Cloud Deployment** (`.github/workflows/deploy.yml`)
- 🌐 Multiple platform support
- 🌐 One-click deployments
- 🌐 Platform-specific configurations

### 3. 🎯 Immediate Next Actions

#### **Option A: Quick Demo Deployment (Recommended)**
```bash
# Push your code
git push origin main

# Go to your GitHub repository
# → Actions tab
# → "Deploy to Cloud" workflow
# → "Run workflow"
# → Choose "huggingface"
# → Your app will be live at https://huggingface.co/spaces/YOUR_USERNAME/qlorax
```

#### **Option B: Full Production Setup**
```bash
# 1. Set up secrets in GitHub (Repository → Settings → Secrets)
GCP_SA_KEY=your-service-account-key  # For Cloud Run
DOCKER_USERNAME=your-docker-username  # For image registry

# 2. Push with training trigger
git commit -m "Deploy production setup [train]"
git push origin main

# 3. Monitor in Actions tab
```

#### **Option C: Local Testing First**
```bash
# Test the Docker build locally
docker-compose build
docker-compose up -d

# Access locally
# http://localhost:7860 (Gradio UI)
# http://localhost:8000 (API)

# If working, push to GitHub
git push origin main
```

### 4. 🔄 Automated Triggers

Your workflows will automatically run when:

- **Every push** → Quick tests and Docker builds
- **Pull requests** → Full validation pipeline  
- **Push to main** → Production deployment
- **Commit with [train]** → Model training
- **Commit with [perf]** → Performance testing
- **Manual trigger** → Deploy to specific platforms

### 5. 📊 Monitoring Your Deployments

#### **GitHub Actions Dashboard**
- Repository → Actions tab
- View build logs and status
- Download artifacts (models, reports)
- Monitor deployment status

#### **Deployment Endpoints**
```bash
# After successful deployment, access:
🤗 Hugging Face: https://huggingface.co/spaces/YOUR_USERNAME/qlorax
☁️ Cloud Run: https://qlorax-[hash]-uc.a.run.app
🚂 Railway: https://qlorax.up.railway.app
🎨 Render: https://qlorax.onrender.com
```

### 6. 🛠️ Customization Options

#### **Modify Training Configuration**
```yaml
# Edit .github/workflows/ci-cd.yml
# In the model-training job, update:
- name: 🏃 Run training
  run: |
    docker run --rm \
      -v $(pwd)/training:/app/training \
      ${{ needs.build-and-test.outputs.image }} \
      python scripts/train_production.py --config configs/your-config.yaml
```

#### **Add Custom Deployment Targets**
```yaml
# Add new job in deploy.yml
deploy-your-platform:
  runs-on: ubuntu-latest
  steps:
    - name: Deploy to Your Platform
      run: |
        # Your deployment commands here
```

#### **Configure Notifications**
```yaml
# Add to secrets:
SLACK_WEBHOOK=your-slack-webhook
DISCORD_WEBHOOK=your-discord-webhook

# Workflows will automatically notify on completion
```

### 7. 🎉 Success Indicators

You'll know everything is working when:

- ✅ Actions tab shows green checkmarks
- ✅ Docker images appear in GitHub Container Registry
- ✅ Deployments are accessible at provided URLs
- ✅ Health checks pass: `/health` endpoint returns 200
- ✅ API documentation available at `/docs`
- ✅ Gradio interface loads and responds

### 8. 🚨 Troubleshooting

#### **Build Failures**
```bash
# Check Actions logs for:
- Dependency installation issues
- Docker build problems
- Test failures

# Common fixes:
- Update requirements versions
- Check Dockerfile syntax
- Verify test dependencies
```

#### **Deployment Issues**
```bash
# Check:
- Secrets configuration
- Platform-specific settings
- Network/port configurations
- Resource limits
```

#### **Model Loading Issues**
```bash
# Verify:
- Model paths in configuration
- Volume mounts in Docker
- Memory/resource limits
- Model file availability
```

### 9. 🔮 Advanced Features

#### **Auto-scaling Production**
```yaml
# Cloud Run with auto-scaling
gcloud run deploy qlorax \
  --min-instances 1 \
  --max-instances 10 \
  --cpu-throttling \
  --memory 4Gi
```

#### **Multi-environment Deployment**
```yaml
# Deploy to staging and production
environments:
  staging:
    url: https://qlorax-staging.example.com
  production:
    url: https://qlorax.example.com
```

#### **Model Training Automation**
```yaml
# Schedule regular training
on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday at 2 AM
```

---

## 🎯 **Your Next Command**

Ready to deploy? Run this:

```bash
git add .
git commit -m "🚀 Deploy QLORAX with GitHub Actions"
git push origin main
```

Then go to your GitHub repository → Actions tab and watch the magic happen! 🎉

Your QLORAX MLOps platform will be live on the internet within minutes!