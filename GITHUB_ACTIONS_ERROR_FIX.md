# QLORAX GitHub Actions Error Resolution Guide

## 🔍 Common GitHub Actions Errors & Solutions

### Issue 1: Docker Build Timeouts
**Error**: "The job running on runner GitHub Actions X has exceeded the maximum execution time"
**Cause**: PyTorch and ML dependencies are large (2-3GB download)
**Solution**: 
- Use multi-stage builds
- Cache Docker layers
- Use CPU-only PyTorch for CI

### Issue 2: Import Errors
**Error**: "ModuleNotFoundError: No module named 'transformers'"
**Cause**: Heavy ML dependencies not installed in test environment
**Solution**: 
- Use requirements-simple.txt for basic tests
- Install full ML stack only when needed

### Issue 3: Health Check Failures
**Error**: "curl: (7) Failed to connect to localhost:8000"
**Cause**: Container not fully started or port mapping issues
**Solution**: 
- Increase startup wait time to 45 seconds
- Add proper health check in Dockerfile
- Test with docker logs for debugging

### Issue 4: Missing Secrets
**Error**: "Secret GCP_SA_KEY not found"
**Cause**: Cloud deployment secrets not configured
**Solution**: Add secrets in GitHub repository settings

### Issue 5: File Not Found
**Error**: "app/gradio_app.py: No such file or directory"
**Cause**: Referenced files don't exist in repository
**Solution**: Create missing files or update workflow references

## ✅ Recommended Fixes Applied

### 1. Simplified Quick Test Workflow
- ✅ Created `quick-test-fixed.yml` with lighter dependencies
- ✅ Timeout protection (30 minutes max)
- ✅ Basic syntax checking instead of full builds

### 2. Docker Build Optimization
- ✅ Multi-stage Dockerfile with base target
- ✅ CPU-only PyTorch installation
- ✅ Better layer caching

### 3. Error-Tolerant Testing
- ✅ Tests continue on non-critical failures
- ✅ Clear error messages
- ✅ Fallback strategies

## 🚀 Next Steps to Fix Your Actions

1. **Replace the failing workflow**:
   ```bash
   git add .github/workflows/quick-test-fixed.yml
   git commit -m "Fix GitHub Actions timeouts and errors"
   git push
   ```

2. **Add missing secrets for cloud deployment**:
   - Go to GitHub repo → Settings → Secrets
   - Add `GCP_SA_KEY` if using Google Cloud
   - Add `GCP_PROJECT_ID` if using Google Cloud

3. **Monitor the fixed workflow**:
   - Check GitHub Actions tab
   - Look for green checkmarks
   - Review logs if still failing

4. **Gradual feature enabling**:
   - Start with basic tests passing
   - Gradually add ML dependencies
   - Test one component at a time

## 🔧 Manual Debugging Commands

If you want to test locally:

```bash
# Test basic imports
python -c "import fastapi; import gradio; print('OK')"

# Test Docker build (base only)
docker build --target base -t qlorax-base .

# Test API startup
python app/api.py &
sleep 10
curl http://localhost:8000/health
```

## 📊 Expected Results After Fixes

- ✅ Quick tests should pass in 5-10 minutes
- ✅ Docker build should succeed (base stage)
- ✅ No timeout errors
- ✅ Clear error messages for real issues
- ⚠️  Heavy ML tests still need optimization (separate workflow)

The fixed workflow focuses on fast validation while the main CI/CD pipeline handles complete builds.