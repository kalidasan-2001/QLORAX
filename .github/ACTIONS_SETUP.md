# GitHub Actions Configuration for QLORAX
# Add these secrets to your GitHub repository settings

## Required Secrets (Repository Settings → Secrets and Variables → Actions)

### For Google Cloud Run Deployment
GCP_SA_KEY=your-google-cloud-service-account-key-json
GCP_PROJECT_ID=your-google-cloud-project-id

### For Container Registry Access (if using private registry)
DOCKER_USERNAME=your-docker-hub-username
DOCKER_PASSWORD=your-docker-hub-password

### For Model Training (optional)
WANDB_API_KEY=your-weights-and-biases-api-key
HUGGINGFACE_TOKEN=your-huggingface-token

### For Notifications (optional)
SLACK_WEBHOOK=your-slack-webhook-url
DISCORD_WEBHOOK=your-discord-webhook-url

## GitHub Actions Features Enabled

✅ Automated testing on every push
✅ Docker image building and pushing
✅ Security vulnerability scanning
✅ Code quality checks
✅ Optional model training
✅ Multi-platform deployment options
✅ Performance testing
✅ Documentation deployment

## Workflow Triggers

1. **Push to main/develop** → Full CI/CD pipeline
2. **Pull Request** → Testing and validation
3. **Manual Trigger** → Deploy to specific platforms
4. **Commit message [train]** → Trigger model training
5. **Commit message [perf]** → Run performance tests

## Next Steps to Set Up GitHub Actions

1. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Add GitHub Actions CI/CD pipeline"
   git push origin main
   ```

2. **Configure Secrets** (if deploying to cloud):
   - Go to GitHub Repository → Settings → Secrets and Variables → Actions
   - Add the secrets listed above based on your deployment needs

3. **Enable Actions**:
   - Go to Actions tab in your repository
   - Workflows will run automatically on push

4. **Monitor Workflows**:
   - Check Actions tab for build status
   - Review logs for any issues
   - Artifacts are saved for download

## Deployment Platforms Supported

### 🤗 Hugging Face Spaces (Recommended for demos)
- Free tier available
- Perfect for showcasing QLORAX
- Automatic Docker builds
- Public or private spaces

### ☁️ Google Cloud Run
- Serverless container deployment
- Pay-per-use scaling
- Production-ready
- Custom domains

### 🚂 Railway
- Developer-friendly
- Git-based deployments
- Free tier for prototypes
- Database integration

### 🎨 Render
- Simple deployment
- GitHub integration
- Free tier available
- Auto-scaling

### 🐳 Self-hosted
- Full control
- Use existing docker-compose.yml
- Suitable for on-premises deployment

## Example Usage

### Trigger Model Training
```bash
git commit -m "Update training config [train]"
git push
```

### Trigger Performance Testing
```bash
git commit -m "Optimize API performance [perf]"
git push
```

### Deploy to Hugging Face
1. Go to Actions tab
2. Select "Deploy to Cloud" workflow
3. Click "Run workflow"
4. Choose "huggingface" as target
5. Follow the printed instructions

## Monitoring and Alerts

- ✅ Build status badges available
- ✅ Security scan results in Security tab
- ✅ Test coverage reports
- ✅ Performance metrics
- ✅ Deployment status notifications

## Cost Optimization

- Uses GitHub-hosted runners (free tier: 2000 minutes/month)
- Docker layer caching enabled
- Conditional job execution
- Lightweight testing approach
- Optional heavy operations (training, performance tests)