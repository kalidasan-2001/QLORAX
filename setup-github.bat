@echo off
REM QLORAX GitHub Repository Setup Script for Windows
REM This script helps you push your QLORAX project to GitHub

echo 🚀 QLORAX GitHub Repository Setup
echo ==================================
echo.

REM Check if we're in a git repository
if not exist ".git" (
    echo ❌ Not in a git repository. Run 'git init' first.
    exit /b 1
)

echo ✅ Git repository detected

REM Check remotes
git remote >nul 2>&1
if errorlevel 1 (
    echo ⚠️  No remote repositories configured
    echo.
    echo 📋 To push to GitHub, you need to:
    echo 1. Create a repository on GitHub.com
    echo 2. Copy the repository URL
    echo 3. Run: git remote add origin YOUR_REPO_URL
    echo 4. Run: git push -u origin main
    echo.
    echo 🌐 GitHub repository creation:
    echo    • Go to: https://github.com/new
    echo    • Repository name: QLORAX
    echo    • Keep it Public (for free GitHub Actions)
    echo    • Don't initialize with README
    echo.
    echo 📝 Commands to run after creating GitHub repository:
    echo git remote add origin https://github.com/YOUR_USERNAME/QLORAX.git
    echo git push -u origin main
    echo.
) else (
    echo ✅ Remote repositories found:
    git remote -v
    echo.
    echo 🚀 Ready to push! Run:
    echo git push -u origin main
)

echo.
echo 📊 Repository status:
git status --short
echo.

REM Check if everything is committed
git diff-index --quiet HEAD -- >nul 2>&1
if not errorlevel 1 (
    echo ✅ All changes committed
    
    echo.
    echo 📦 Repository ready to push
    
    echo.
    echo 🎯 After pushing, your GitHub Actions will:
    echo    • Build Docker images
    echo    • Run automated tests  
    echo    • Enable one-click deployments
    echo    • Set up CI/CD pipeline
    
) else (
    echo ⚠️  You have uncommitted changes
    echo Run 'git add .' and 'git commit -m "message"' first
)

echo.
echo 🎉 Once pushed, visit your GitHub repository's Actions tab!
echo 🌐 Deploy to Hugging Face Spaces, Cloud Run, Railway, or Render!